///|
/// How serious a finding is. `Error` breaks the concept-card format;
/// `Warning` is a deviation the library tolerates, such as a sentence that
/// ends in a noun instead of `です。`.
pub(all) enum Severity {
  Error
  Warning
} derive(Eq)

///|
pub fn Severity::label(self : Severity) -> String {
  match self {
    Error => "error"
    Warning => "warning"
  }
}

///|
pub(all) struct Finding {
  rule : String
  severity : Severity
  message : String
}

///|
pub(all) struct Report {
  id : String
  title : String
  findings : Array[Finding]
  /// Card ids referenced by inline mentions. Checking that they exist needs
  /// the CLI, so it is left to the caller.
  mentions : Array[String]
}

///|
pub fn Report::errors(self : Report) -> Int {
  self.findings.filter(fn(f) { f.severity == Error }).length()
}

///|
pub fn Report::render(self : Report) -> Json {
  let findings : Array[Json] = self.findings.map(fn(f) {
    {
      "rule": f.rule.to_json(),
      "severity": f.severity.label().to_json(),
      "message": f.message.to_json(),
    }
  })
  {
    "id": self.id.to_json(),
    "title": self.title.to_json(),
    "ok": (self.errors() == 0).to_json(),
    "findings": findings.to_json(),
    "mentions": self.mentions.to_json(),
  }
}

///|
fn error(out : Array[Finding], rule : String, message : String) -> Unit {
  out.push({ rule, severity: Error, message })
}

///|
fn warning(out : Array[Finding], rule : String, message : String) -> Unit {
  out.push({ rule, severity: Warning, message })
}

// Character classes ---------------------------------------------------------

///|
fn in_range(c : Char, lo : Int, hi : Int) -> Bool {
  let n = c.to_int()
  n >= lo && n <= hi
}

///|
/// Kana, kanji, and the marks used inside Japanese words (ー・々).
fn is_japanese(c : Char) -> Bool {
  in_range(c, 0x3040, 0x30FF) ||
  in_range(c, 0x3400, 0x4DBF) ||
  in_range(c, 0x4E00, 0x9FFF) ||
  in_range(c, 0xF900, 0xFAFF) ||
  in_range(c, 0x20000, 0x2FFFF) ||
  c == '々' ||
  c == '〆'
}

///|
/// Scripts whose transliterations must also carry a romanization. Han is
/// deliberately absent: a Japanese reader reads 三不粘 or 風車 directly.
fn needs_romanization(c : Char) -> Bool {
  in_range(c, 0x0370, 0x03FF) || // Greek
  in_range(c, 0x1F00, 0x1FFF) || // Greek, polytonic
  in_range(c, 0x0400, 0x04FF) || // Cyrillic
  in_range(c, 0x0530, 0x058F) || // Armenian
  in_range(c, 0x0590, 0x05FF) || // Hebrew
  in_range(c, 0x0600, 0x06FF) || // Arabic
  in_range(c, 0x0750, 0x077F) || // Arabic supplement
  in_range(c, 0x0900, 0x097F) || // Devanagari
  in_range(c, 0x0E00, 0x0E7F) || // Thai
  in_range(c, 0x10A0, 0x10FF) // Georgian
}

///|
fn is_latin_letter(c : Char) -> Bool {
  (c >= 'A' && c <= 'Z') ||
  (c >= 'a' && c <= 'z') ||
  in_range(c, 0x00C0, 0x024F) ||
  in_range(c, 0x1E00, 0x1EFF)
}

// Title ----------------------------------------------------------------------

///|
/// Contents of each bracket group, with the index of its opening bracket.
fn groups(
  chars : Array[Char],
  open : Char,
  close : Char,
) -> Array[(Int, String)] {
  let found = []
  let mut i = 0
  while i < chars.length() {
    if chars[i] == open {
      let start = i
      let buf = StringBuilder()
      i = i + 1
      while i < chars.length() && chars[i] != close {
        buf.write_char(chars[i])
        i = i + 1
      }
      found.push((start, buf.to_string()))
    }
    i = i + 1
  }
  found
}

///|
fn check_title(title : String, out : Array[Finding]) -> Unit {
  let chars : Array[Char] = title.iter().collect()
  if chars.contains('（') || chars.contains('）') {
    error(
      out, "title.fullwidth_paren", "title uses full-width （）; concept cards use half-width ()",
    )
  }
  for i in 1..<chars.length() {
    if chars[i] == '(' && (chars[i - 1] == ' ' || chars[i - 1] == '\u{3000}') {
      error(
        out, "title.space_before_paren", "title has a space before (; write 頭名(reading) with no space",
      )
      break
    }
  }
  let parens = groups(chars, '(', ')')
  let lenticular = groups(chars, '【', '】')
  if parens.length() > 1 {
    error(
      out,
      "title.multiple_paren_groups",
      "title has \{parens.length()} () groups; at most one is allowed",
    )
  }
  if lenticular.length() > 1 {
    error(
      out,
      "title.multiple_lenticular_groups",
      "title has \{lenticular.length()} 【】 groups; at most one is allowed",
    )
  }
  if parens.length() > 0 &&
    lenticular.length() > 0 &&
    parens[parens.length() - 1].0 > lenticular[0].0 {
    error(
      out, "title.bracket_order", "() comes after 【】; the combined form is 頭名(reading)【category】",
    )
  }
  for group in lenticular {
    let body = group.1
    if body.is_empty() || !body.iter().all(is_japanese) {
      error(
        out,
        "title.lenticular_content",
        "【\{body}】 must hold a short Japanese category word, not a reading",
      )
    }
  }
  for group in parens {
    let body : Array[Char] = group.1.iter().collect()
    if body.iter().any(needs_romanization) {
      let mut comma = -1
      for j, c in body {
        if c == ',' {
          comma = j
        }
      }
      let romanized = comma >= 0 && body[comma + 1:].iter().any(is_latin_letter)
      if !romanized {
        error(
          out,
          "title.missing_romanization",
          "(\{group.1}) is in a non-Latin script; add the romanization: (script, romanization)",
        )
      }
    }
  }
}

// JSON access -----------------------------------------------------------------

///|
fn field(obj : Json, key : String) -> Json? {
  match obj {
    Object(m) => m.get(key)
    _ => None
  }
}

///|
fn str_field(obj : Json, key : String) -> String? {
  match field(obj, key) {
    Some(String(s)) => Some(s)
    _ => None
  }
}

///|
fn arr_field(obj : Json, key : String) -> Array[Json] {
  match field(obj, key) {
    Some(Array(a)) => a
    _ => []
  }
}

///|
fn node_type(node : Json) -> String {
  str_field(node, "type").unwrap_or("?")
}

///|
fn has_mark(node : Json, mark : String) -> Bool {
  arr_field(node, "marks").iter().any(fn(m) { node_type(m) == mark })
}

///|
fn text_nodes(block : Json) -> Array[Json] {
  arr_field(block, "content").filter(fn(n) { node_type(n) == "text" })
}

///|
fn plain_text(block : Json) -> String {
  let buf = StringBuilder()
  for n in text_nodes(block) {
    buf.write_string(str_field(n, "text").unwrap_or(""))
  }
  buf.to_string()
}

///|
fn collect_text(node : Json, buf : StringBuilder) -> Unit {
  match str_field(node, "text") {
    Some(t) => buf.write_string(t)
    None => ()
  }
  for child in arr_field(node, "content") {
    collect_text(child, buf)
  }
}

///|
fn join(items : Array[String], sep : String) -> String {
  let buf = StringBuilder()
  for i, s in items {
    if i > 0 {
      buf.write_string(sep)
    }
    buf.write_string(s)
  }
  buf.to_string()
}

// Body -------------------------------------------------------------------------

///|
fn check_shape(kinds : Array[String], out : Array[Finding]) -> Unit {
  if kinds != ["heading", "paragraph"] &&
    kinds != ["heading", "paragraph", "paragraph"] {
    error(
      out,
      "body.shape",
      "body blocks are [\{join(kinds, ", ")}]; expected heading + one paragraph, plus an optional 出典 paragraph",
    )
  }
}

///|
fn check_heading(heading : Json, title : String, out : Array[Finding]) -> Unit {
  match field(heading, "attrs") {
    Some(attrs) =>
      match field(attrs, "level") {
        Some(Number(n, ..)) if n == 1.0 => ()
        _ => error(out, "heading.level", "the heading must be H1")
      }
    None => error(out, "heading.level", "the heading must be H1")
  }
  let texts = text_nodes(heading)
  if texts.is_empty() || !texts.iter().all(fn(n) { has_mark(n, "strong") }) {
    error(
      out, "heading.not_bold", "the H1 text must be bold in its entirety (# **Title**)",
    )
  }
  let text = plain_text(heading)
  if text != title {
    error(
      out,
      "heading.title_mismatch",
      "H1 text \"\{text}\" does not repeat the title verbatim",
    )
  }
}

///|
fn check_sentence(
  para : Json,
  out : Array[Finding],
  mentions : Array[String],
) -> Unit {
  for n in arr_field(para, "content") {
    match node_type(n) {
      "text" => ()
      "card" =>
        match field(n, "attrs") {
          Some(attrs) =>
            match str_field(attrs, "cardId") {
              Some(id) => mentions.push(id)
              None => ()
            }
          None => ()
        }
      other =>
        error(
          out,
          "sentence.disallowed_node",
          "the definition contains a \{other} node; only text and card mentions belong there",
        )
    }
  }
  let text = plain_text(para)
  let mut periods = 0
  for c in text {
    if c == '。' {
      periods += 1
    }
  }
  if periods == 0 {
    // A noun phrase with no 。 (饕餮's "…怪物もしくは霊獣") is the same
    // tolerated deviation as one ending in "…グループ。".
    warning(
      out, "sentence.ending", "the definition is a noun phrase with no 。; new cards end in です。",
    )
  } else if periods > 1 {
    error(
      out,
      "sentence.count",
      "the definition has \{periods} sentences; merge them into one",
    )
  } else if !text.has_suffix("。") {
    error(
      out, "sentence.count", "text continues after the 。; the definition must be one sentence",
    )
  } else if !text.has_suffix("です。") {
    warning(
      out, "sentence.ending", "the sentence does not end in です。 (nearly every concept card does)",
    )
  }
}

///|
fn check_source(para : Json, out : Array[Finding]) -> Unit {
  if !plain_text(para).has_prefix("出典: ") {
    error(
      out, "source.format", "a third paragraph is only allowed as \"出典: <link>\"",
    )
  }
  if !text_nodes(para).iter().any(fn(n) { has_mark(n, "link") }) {
    error(
      out, "source.no_link", "the 出典 URL is not a link; write 出典: [<URL>](<URL>)",
    )
  }
}

///|
/// Lint one concept card. `note_json` is the raw output of
/// `heptabase note read`; `props_json`, when given, is the output of
/// `heptabase card properties` and enables the tag check.
pub fn lint_note(note_json : String, props_json? : String) -> Report raise {
  let note = @json.parse(note_json)
  let id = str_field(note, "id").unwrap_or("")
  let title = str_field(note, "title").unwrap_or("")
  let out : Array[Finding] = []
  let mentions : Array[String] = []
  match str_field(note, "error") {
    Some(message) => {
      error(out, "input.cli_error", message)
      return { id, title, findings: out, mentions }
    }
    None => ()
  }
  check_title(title, out)
  let content = match str_field(note, "content") {
    Some(c) => c
    None => {
      error(out, "input.no_content", "the note JSON has no content field")
      return { id, title, findings: out, mentions }
    }
  }
  let doc = @json.parse(content)
  let blocks = arr_field(doc, "content")
  let kinds = blocks.map(node_type)
  check_shape(kinds, out)
  if kinds.length() > 0 && kinds[0] == "heading" {
    check_heading(blocks[0], title, out)
  } else {
    error(out, "heading.missing", "the card must open with the H1 heading")
  }
  if kinds.length() > 1 && kinds[1] == "paragraph" {
    check_sentence(blocks[1], out, mentions)
  }
  if kinds.length() == 3 && kinds[2] == "paragraph" {
    check_source(blocks[2], out)
  }
  let all = StringBuilder()
  for b in blocks {
    collect_text(b, all)
  }
  if all.to_string().contains("{{card") {
    error(
      out, "mention.unparsed", "a literal {{card …}} survived; the mention did not parse",
    )
  }
  match props_json {
    Some(p) =>
      if arr_field(@json.parse(p), "tags").is_empty() {
        error(out, "tags.none", "the card has no tag")
      }
    None => ()
  }
  { id, title, findings: out, mentions }
}
