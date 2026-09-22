// Fixtures under ../fixtures are real cards dumped with `heptabase note read`
// and `heptabase card properties`. pass_* follow the format; fail_* and
// warn_* break it in the ways the library actually does; limit_* documents
// what a mechanical check cannot see.

///|
fn fixture(name : String) -> @lint.Report raise {
  let note = @fs.read_file_to_string("fixtures/\{name}.json")
  let props = @fs.read_file_to_string("fixtures/\{name}.props.json")
  @lint.lint_note(note, props_json=props)
}

///|
fn rules(report : @lint.Report) -> Array[String] {
  report.findings.map(fn(f) { f.rule })
}

///|
test "exemplars pass clean" {
  for
    name in [
      "pass_bagna_cauda", "pass_basileus", "pass_dokuso", "pass_wojtek", "pass_kazaguruma",
      "pass_sanbuzhan",
    ] {
    assert_eq((name, rules(fixture(name))), (name, []))
  }
}

///|
test "inline mentions are collected" {
  assert_eq(fixture("pass_bagna_cauda").mentions, [
    "093f9041-cec5-4509-9371-24e83c1b525a",
  ])
}

///|
test "解説: a card pointer to the explainer note passes, and is collected too" {
  let report = fixture("pass_kaisetsu")
  assert_eq(rules(report), [])
  assert_eq(report.mentions, [
    "093f9041-cec5-4509-9371-24e83c1b525a", "11111111-1111-4111-8111-111111111111",
  ])
}

// Either order passes: a card that already had 出典 gains its 解説 line
// through `note append`, which can only add at the end.
test "解説 after 出典 is fine too" {
  assert_eq(rules(fixture("pass_kaisetsu_after_source")), [])
}

///|
test "ゴディバ夫人: full-width parens and appended sections" {
  assert_eq(rules(fixture("fail_godiva")), [
    "title.fullwidth_paren", "body.shape",
  ])
}

///|
// Its body is heading + three paragraphs, which the 解説 line made a legal
// shape, so the memo is now caught by what those trailing paragraphs hold
// rather than by their number. Still rejected.
test "KATANA:GO: spaced paren, product memo in the trailing paragraphs" {
  assert_eq(rules(fixture("fail_katana")), [
    "title.space_before_paren", "sentence.ending", "trailing.format", "trailing.format",
  ])
}

///|
test "サロメ(戯曲): bullet-list note with a plain H1" {
  assert_eq(rules(fixture("fail_salome")), ["body.shape", "heading.not_bold"])
}

///|
test "饕餮: a noun phrase with no 。 is a warning, like a noun ending with one" {
  let report = fixture("warn_toutetsu")
  assert_eq(rules(report), ["sentence.ending"])
  assert_eq(report.errors(), 0)
}

///|
test "ボリシェビキ: noun ending is a warning, not an error" {
  let report = fixture("warn_bolsheviki")
  assert_eq(rules(report), ["sentence.ending"])
  assert_eq(report.errors(), 0)
}

///|
test "ハムサ(Hamsa): a missing original script is invisible to the checker" {
  // Whether a Latin-only reading needs a script depends on the word's
  // origin, which the card does not record.
  assert_eq(rules(fixture("limit_hamsa")), [])
}

// Synthetic cards for rules no real card currently breaks ----------------------

///|
fn text(s : String) -> Json {
  { "type": "text", "text": s.to_json() }
}

///|
fn bold(s : String) -> Json {
  { "type": "text", "marks": [{ "type": "strong" }], "text": s.to_json() }
}

///|
fn link(url : String) -> Json {
  {
    "type": "text",
    "marks": [{ "type": "link", "attrs": { "href": url.to_json() } }],
    "text": url.to_json(),
  }
}

///|
fn heading(nodes : Array[Json], level? : Int = 1) -> Json {
  {
    "type": "heading",
    "attrs": { "level": level.to_json() },
    "content": nodes.to_json(),
  }
}

///|
fn para(nodes : Array[Json]) -> Json {
  { "type": "paragraph", "content": nodes.to_json() }
}

///|
fn note(title : String, blocks : Array[Json]) -> String {
  let doc : Json = { "type": "doc", "content": blocks.to_json() }
  let outer : Json = {
    "id": "synthetic",
    "title": title.to_json(),
    "content": doc.stringify().to_json(),
  }
  outer.stringify()
}

///|
fn check(title : String, blocks : Array[Json]) -> Array[String] raise {
  rules(@lint.lint_note(note(title, blocks)))
}

///|
fn title_rules(title : String) -> Array[String] raise {
  check(title, [heading([bold(title)]), para([text("定義です。")])])
}

///|
test "non-Latin readings need a romanization; Han does not" {
  assert_eq(title_rules("ネフェレー(Νεφέλη)"), [
    "title.missing_romanization",
  ])
  assert_eq(title_rules("ネフェレー(Νεφέλη, Nephele)"), [])
  assert_eq(title_rules("アムリタ(अमृत)"), [
    "title.missing_romanization",
  ])
  assert_eq(title_rules("アムリタ(अमृत, amṛta)"), [])
  assert_eq(title_rules("タガネ(鏨)"), [])
}

///|
test "bracket placement" {
  assert_eq(title_rules("アップル(Apple)【企業】"), [])
  assert_eq(title_rules("アップル【企業】(Apple)"), [
    "title.bracket_order",
  ])
  assert_eq(title_rules("バシレウス【βασιλεύς, Basileus】"), [
    "title.lenticular_content",
  ])
  assert_eq(title_rules("アンチョビ\u{3000}(anchovy)"), [
    "title.space_before_paren",
  ])
  assert_eq(title_rules("A(b)(c)"), ["title.multiple_paren_groups"])
}

///|
test "heading must be a bold H1 repeating the title" {
  let body = para([text("定義です。")])
  assert_eq(
    check("タガネ(鏨)", [heading([text("タガネ(鏨)")]), body]),
    ["heading.not_bold"],
  )
  assert_eq(check("タガネ(鏨)", [heading([bold("タガネ")]), body]), [
    "heading.title_mismatch",
  ])
  assert_eq(
    check("タガネ(鏨)", [heading([bold("タガネ(鏨)")], level=2), body]),
    ["heading.level"],
  )
}

///|
test "one sentence, no stray nodes, no unparsed mention" {
  let h = heading([bold("X")])
  assert_eq(
    check("X", [h, para([text("一文目です。二文目です。")])]),
    ["sentence.count"],
  )
  assert_eq(check("X", [h, para([text("定義です。補足")])]), [
    "sentence.count",
  ])
  assert_eq(
    check("X", [
      h,
      para([text("式 "), { "type": "math_inline" }, text("です。")]),
    ]),
    ["sentence.disallowed_node"],
  )
  assert_eq(
    check("X", [
      h,
      para([
        text(
          "にんにく、{{card 093f9041-cec5-4509-9371-24e83c1b525a}}、オリーブです。",
        ),
      ]),
    ]),
    ["mention.unparsed"],
  )
}

///|
test "出典 paragraph must be a labelled link" {
  let h = heading([bold("X")])
  let d = para([text("定義です。")])
  assert_eq(
    check("X", [h, d, para([text("出典: "), link("https://example.com")])]),
    [],
  )
  assert_eq(check("X", [h, d, para([text("出典: https://example.com")])]), [
    "source.no_link",
  ])
  // An unrecognized label is caught as a trailing paragraph, not as a
  // malformed 出典 — the label is what picks the rule.
  assert_eq(
    check("X", [h, d, para([text("Source: "), link("https://example.com")])]),
    ["trailing.format"],
  )
  assert_eq(check("X", [h, d, para([text("出典:https://example.com")])]), [
    "source.format", "source.no_link",
  ])
}

///|
test "tags and CLI errors" {
  let ok = note("X", [heading([bold("X")]), para([text("定義です。")])])
  assert_eq(rules(@lint.lint_note(ok, props_json="{\"tags\":[]}")), [
    "tags.none",
  ])
  assert_eq(
    rules(@lint.lint_note("{\"error\":\"Heptabase CLI cannot connect\"}")),
    ["input.cli_error"],
  )
}
