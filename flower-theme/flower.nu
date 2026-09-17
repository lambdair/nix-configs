def state-file []: nothing -> path {
  $env.XDG_STATE_HOME? | default ($env.HOME | path join ".local" "state")
  | path join "flower-theme" "selection"
}

# Activating a specialisation records it as a new generation that has no
# specialisations of its own, so the newest generation that does is the base.
def base-generation []: nothing -> path {
  let profiles = (
    $env.XDG_STATE_HOME? | default ($env.HOME | path join ".local" "state")
    | path join "nix" "profiles"
  )
  let base = (
    ls ($profiles | path join "home-manager-*-link" | into glob)
    | insert n {|l| $l.name | path basename | parse "home-manager-{n}-link" | get n.0 | into int }
    | sort-by n --reverse
    | where {|l| $l.name | path join "specialisation" | path exists }
  )
  if ($base | is-empty) {
    error make { msg: "no home-manager generation with flower specialisations; run `just home-mac` first" }
  }
  $base.0.name | path expand
}

# The variant Claude Code is set to, which every port follows.
def active []: nothing -> string {
  let settings = ($env.HOME | path join ".claude" "settings.json")
  if not ($settings | path exists) { return "" }
  open $settings | get theme? | default "" | str replace "custom:" ""
}

def activate [generation: path, name: string] {
  let result = (do { ^($generation | path join "activate") } | complete)
  if $result.exit_code != 0 {
    print --stderr $result.stderr
    error make { msg: $"activating ($name) failed" }
  }
}

# cmux paints the theme from its own state, so it is told directly. A failure
# is ignored, since cmux may not be running.
def tell-cmux [name?: string] {
  try {
    if $name == null {
      ^cmux themes clear o+e>| ignore
    } else {
      ^cmux themes set --light $name --dark $name o+e>| ignore
    }
  }
}

# Switch every themed tool to another flower.
#
# Activates one of the flower specialisations the home-manager configuration
# prebuilds. With no arguments, prints the active flower.
#
# Flowers: anemone, nemophila, sunflower. Modes: dark, light.
@example "show the active flower" { flower }
@example "switch to a flower and mode" { flower sunflower light }
@example "switch flower, keeping the current mode" { flower sunflower }
@example "go back to the flower the configuration names" { flower reset }
def main [
  flower?: string # anemone, nemophila or sunflower
  mode?: string # dark or light; defaults to the current mode
  --reapply # activate the saved choice again, after a rebuild
] {
  let state = (state-file)

  if $reapply {
    if not ($state | path exists) { return }
    let name = (open $state | str trim)
    let generation = (base-generation) | path join "specialisation" $name
    if not ($generation | path exists) {
      rm $state
      return
    }
    activate $generation $name
    tell-cmux $name
    return
  }

  if $flower == null {
    print (active)
    return
  }

  let base = (base-generation)
  let current = (active | parse "flower-{flower}-{mode}")
  let chosen_mode = $mode | default ($current.mode.0? | default "dark")
  let name = $"flower-($flower)-($chosen_mode)"
  let generation = $base | path join "specialisation" $name
  if not ($generation | path exists) {
    let known = (ls ($base | path join "specialisation") | get name | path basename | str join ", ")
    error make { msg: $"unknown flower variant ($name); available: ($known)" }
  }

  activate $generation $name
  mkdir ($state | path dirname)
  $name | save --force $state
  tell-cmux $name
  print $"flower: ($name)"
  print "Restart kitty, jjui, hunk, yazi, lazygit, television and zellij sessions, run :config-reload in Helix, and open a new shell for the prompt and fzf."
}

# Go back to the flower the configuration names.
def "main reset" [] {
  activate (base-generation) "the configured flower"
  rm --force (state-file)
  tell-cmux
  print $"flower: back to (active)"
}
