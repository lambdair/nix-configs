///|
/// Usage: moonrun main.wasm -- <note.json> [<props.json>]
///
/// Prints the lint report as JSON. The wasm target cannot spawn processes, so
/// fetching the JSON from the Heptabase CLI is left to lint-card.nu.
fn main {
  let args = @env.args()
  // args[0] is the wasm module itself.
  if args.length() < 2 {
    fail_with("usage: hepta-lint <note.json> [<props.json>]")
    return
  }
  let note = read(args[1])
  let props = if args.length() >= 3 { read(args[2]) } else { None }
  guard note is Some(note) else { return }
  let report = @lint.lint_note(note, props_json?=props) catch {
    _ => {
      fail_with("could not parse the note JSON")
      return
    }
  }
  println(report.render().stringify())
}

///|
fn read(path : String) -> String? {
  Some(@fs.read_file_to_string(path)) catch {
    _ => {
      fail_with("could not read \{path}")
      None
    }
  }
}

///|
fn fail_with(message : String) -> Unit {
  let report : Json = { "ok": false, "error": message.to_json() }
  println(report.stringify())
}
