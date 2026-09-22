# Lint one Heptabase concept card against the concept-card format.
#
# Fetches the card through the Heptabase CLI and runs hepta-lint (MoonBit,
# compiled to wasm) over it. The checks that need the CLI happen here: that
# every inline mention points at a live card, and, with --whiteboard, that the
# card sits on that board. Prints the report as JSON; exits 1 when it holds
# any error-severity finding.
def main [
  card_id: string
  --whiteboard (-w): string # id of the whiteboard the card should be on
] {
  let root = $env.FILE_PWD | path join hepta-lint
  let wasm = $root | path join _build wasm release build cmd main main.wasm
  let build = do { cd $root; ^moon build --target wasm --release } | complete
  if $build.exit_code != 0 {
    error make { msg: $"hepta-lint failed to build:\n($build.stdout)($build.stderr)" }
  }

  # A failed CLI call still yields JSON ({"error": ...}); hepta-lint turns
  # that into an input.cli_error finding.
  let tmp = mktemp -d
  let note = $tmp | path join note.json
  let props = $tmp | path join props.json
  (hepta note read $card_id).text | save -f $note
  (hepta card properties $card_id).text | save -f $props
  mut report = ^moonrun $wasm -- $note $props | from json
  rm -rf $tmp

  if ($report | get -o error) != null {
    print ($report | to json)
    exit 1
  }

  mut extra = []
  for id in $report.mentions {
    let found = hepta card properties $id
    if not $found.ok {
      $extra = $extra | append {
        rule: "mention.missing_card"
        severity: "error"
        message: $"inline mention of ($id) is broken: (cli-error $found)"
      }
    }
  }
  if $whiteboard != null {
    let board = hepta whiteboard cards $whiteboard
    if not $board.ok {
      $extra = $extra | append {
        rule: "whiteboard.unknown"
        severity: "error"
        message: $"could not read whiteboard ($whiteboard): (cli-error $board)"
      }
    } else {
      let board = $board.text | from json
      if ($board.cards | where cardId == $card_id | is-empty) {
        $extra = $extra | append {
          rule: "whiteboard.not_placed"
          severity: "error"
          message: $"the card is not on ($board.whiteboardName)"
        }
      }
    }
  }

  let findings = $report.findings | append $extra
  let ok = $findings | where severity == "error" | is-empty
  $report = $report | merge { findings: $findings, ok: $ok }
  print ($report | to json)
  if not $ok { exit 1 }
}

# Run the Heptabase CLI without letting a failure abort the script. On failure
# the CLI exits non-zero and writes its JSON error to stderr.
def hepta [...args: string]: nothing -> record<ok: bool, text: string> {
  let r = ^heptabase ...$args | complete
  if $r.exit_code == 0 {
    { ok: true, text: $r.stdout }
  } else {
    { ok: false, text: $r.stderr }
  }
}

def cli-error [r: record<ok: bool, text: string>]: nothing -> string {
  try { $r.text | from json | get error } catch { $r.text | str trim }
}
