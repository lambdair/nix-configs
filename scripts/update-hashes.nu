#!/usr/bin/env nu

# Recompute the dependency hashes written by hand in pkgs/. Each one pins the
# result of a fetch that the package's own source dictates — pnpm's dependency
# set, a cargo git dependency — so an nvfetcher source bump leaves it stale and
# the build then fails with the new dependencies missing from the sandbox.
# The update workflow runs this so the pull request it opens is self-consistent.

# Building with a placeholder forces the fetch to run; its mismatch error
# reports the hash the current source really produces.
const FAKE = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

# One row per hash: `anchor` is the literal text in front of it, `attr` the
# derivation under ./pkgs whose build reports the value.
const TARGETS = [
  [file anchor attr];
  ["pkgs/difit.nix" 'hash = "' "difit.pnpmDeps"]
  ["pkgs/helix-steel.nix" 'steelCoreHashForHelix = "' "helix-steel-unwrapped.cargoDeps"]
  ["pkgs/helix-steel.nix" 'steelCoreHashForSulafat = "' "sulafat.cargoDeps"]
]

# The package set is evaluated straight from the checkout, so every derivation
# under pkgs/ is addressable by its attribute path.
const EXPR = '
let
  flake = builtins.getFlake "@ROOT@";
  pkgs = import flake.inputs.nixpkgs {
    system = builtins.currentSystem;
    config.allowUnfree = true;
  };
  sources = pkgs.callPackage @ROOT@/_sources/generated.nix { };
in
(import @ROOT@/pkgs { inherit pkgs sources; }).@ATTR@
'

# The hash between `anchor` and the quote closing it.
def current-hash [text: string, anchor: string]: nothing -> any {
  let start = ($text | str index-of $anchor)
  if $start < 0 {
    return null
  }
  let from = ($start + ($anchor | str length))
  $text | str substring $from.. | split row '"' | first
}

def build-hash [root: string, attr: string]: nothing -> any {
  let expr = ($EXPR | str replace --all "@ROOT@" $root | str replace "@ATTR@" $attr)
  let result = (do { ^nix build --impure --no-link --expr $expr } | complete)
  let got = ($result.stderr | parse --regex 'got:\s+(?<hash>sha256-[A-Za-z0-9+/=]+)')
  if ($got | is-empty) { null } else { $got | first | get hash }
}

def main [] {
  let root = ($env.FILE_PWD | path dirname)
  mut skipped = []

  for target in $TARGETS {
    let path = ($root | path join $target.file)
    let text = (open --raw $path)
    let current = (current-hash $text $target.anchor)
    if $current == null {
      print $"($target.file): anchor ($target.anchor) not found, skipping"
      $skipped = ($skipped | append $target.attr)
      continue
    }

    $text | str replace ($target.anchor + $current) ($target.anchor + $FAKE) | save --force $path
    let got = (build-hash $root $target.attr)
    let new = if $got == null { $current } else { $got }
    open --raw $path | str replace ($target.anchor + $FAKE) ($target.anchor + $new) | save --force $path

    if $got == null {
      print $"($target.attr): no hash reported, left at ($current)"
      $skipped = ($skipped | append $target.attr)
    } else if $got == $current {
      print $"($target.attr): unchanged"
    } else {
      print $"($target.attr): ($current) -> ($got)"
    }
  }

  if not ($skipped | is-empty) {
    print $"could not recompute: ($skipped | str join ', ')"
  }
}
