# Emit the catalog read by television's `tools` channel: one row per installed
# package that ships executables, plus one row per nushell alias.
#
# Writes catalog.txt (the channel source) and catalog.json (looked up by the
# preview script) into the given output directory.

# Packages whose executables share no prefix with the package name, so the
# fallback below would otherwise pick a misleading representative.
const OVERRIDES = {
  "graphviz": "dot",
  "rust-default": "cargo",
}

# The command shown first for a package: mainProgram when upstream sets it,
# then progressively looser name matches, then the shortest name.
def primary-command [name: string, main: string, cmds: list<string>]: nothing -> string {
  let override = ($OVERRIDES | get -o $name)
  let exact = if ($name in $cmds) { $name } else { null }
  let shortens = ($cmds | where {|c| $name | str starts-with $c } | sort | sort-by {|c| $c | str length} | last)
  let extends = ($cmds | where {|c| $c | str starts-with $name } | sort | sort-by {|c| $c | str length} | first)
  let shortest = ($cmds | sort | sort-by {|c| $c | str length} | first)
  let from_main = if ($main != "" and ($main in $cmds)) { $main } else { null }

  [$override $from_main $exact $shortens $extends $shortest] | compact | first
}

def main [packages_file: string, aliases_file: string, out_dir: string] {
  let packages = (
    open --raw $packages_file | from json
    | each {|p|
        let bin = ($p.path | path join "bin")
        let cmds = if ($bin | path exists) { ls $bin | get name | path basename | sort } else { [] }
        if ($cmds | is-empty) {
          null
        } else {
          let primary = (primary-command $p.name $p.main $cmds)
          let others = ($cmds | where {|c| $c != $primary })
          {
            cmd: $primary
            kind: "pkg"
            title: $p.name
            desc: $p.desc
            others: $others
            path: $p.path
          }
        }
      }
    | compact
  )

  let aliases = (
    open --raw $aliases_file | from json
    | transpose name expansion
    | each {|a| { cmd: $a.name, kind: "alias", title: $a.expansion, desc: "", others: [], path: "" } }
  )

  let rows = ($packages | append $aliases | sort-by cmd --ignore-case)
  # Capped so a handful of long language-server names cannot indent every row.
  let width = ([($rows | get cmd | each {|c| $c | str length} | math max) 14] | math min)

  $rows
  | each {|r|
      let others = if ($r.others | is-empty) { "" } else { $"  \(($r.others | str join ' ')\)" }
      let desc = if ($r.desc == "") { "" } else { $"  ($r.desc)" }
      $"(($r.cmd | fill --alignment left --width $width))  (($r.kind | fill --alignment left --width 5))  ($r.title)($desc)($others)"
    }
  | str join "\n"
  | $"($in)\n"
  | save --force ($out_dir | path join "catalog.txt")

  $rows | to json | save --force ($out_dir | path join "catalog.json")
}
