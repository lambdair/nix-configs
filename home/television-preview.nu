# Render the preview panel for television's `tools` channel.
#
# Shows what the entry is, then how to use it: the tldr page when one exists,
# otherwise the tool's own --help. Both are bounded by `timeout` so a missing
# tldr cache cannot leave the panel hanging on a network fetch.

def usage [timeout_bin: string, tldr_bin: string, cmd: string, path: string]: nothing -> string {
  let tldr = (do { ^$timeout_bin 3 $tldr_bin $cmd } | complete)
  if $tldr.exit_code == 0 and ($tldr.stdout | str trim | is-not-empty) {
    return $tldr.stdout
  }

  # A package shipping a macOS .app launches its window rather than printing
  # help, so it gets no --help fallback.
  if ($path | path join "Applications" | path exists) { return "" }

  let bin = ($path | path join "bin" $cmd)
  if not ($bin | path exists) { return "" }

  let help = (do { ^$timeout_bin 3 $bin --help } | complete)
  let text = if ($help.stdout | str trim | is-not-empty) { $help.stdout } else { $help.stderr }
  $text | lines | first 60 | str join "\n"
}

def main [catalog_file: string, timeout_bin: string, tldr_bin: string, cmd: string] {
  let row = (open --raw $catalog_file | from json | where cmd == $cmd | get -o 0)
  if $row == null {
    print $cmd
    return
  }

  print $row.title
  if $row.desc != "" { print $row.desc }
  print ""

  if $row.kind == "alias" { return }

  print $"commands: (([$row.cmd] | append $row.others) | str join ' ')"
  print ""
  print (usage $timeout_bin $tldr_bin $row.cmd $row.path)
}
