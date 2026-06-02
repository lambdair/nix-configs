#!/usr/bin/env nu
# Self-test for check-workarounds.nu. Run from repo root:
#   nu home/claude/skills/checking-removable-nix-workarounds/test-check-workarounds.nu
use std assert

let here = ($env.FILE_PWD)
let helper = ($here | path join "check-workarounds.nu")

# currentSystem under eval (e.g. "aarch64-darwin")
let sys = (^nix eval --impure --raw --expr 'builtins.currentSystem' | str trim)

# Built by concatenation, not `$"..."`: nushell interpolation parses `(...)` as
# subexpressions, which would mangle the literal `(builtins.getFlake ...)` parens.

# ok-hello: tiny, substituted from cache.nixos.org in well under a second.
# fail-throw: fails at eval instantly, no network.
let ok_expr = "(builtins.getFlake (toString ./.)).inputs.nixpkgs.legacyPackages." + $sys + ".hello"
let fail_expr = 'builtins.throw "removability-test-sentinel"'

let jobs = [
  { label: "ok-hello",   expr: $ok_expr }
  { label: "fail-throw", expr: $fail_expr }
]

let out = ($jobs | to json | ^nu $helper | from json)

let ok_row   = ($out | where label == "ok-hello"   | first)
let fail_row = ($out | where label == "fail-throw" | first)

assert ($out | length | $in == 2) "should return one row per job"
assert ($ok_row.ok) "hello should build/substitute successfully"
assert (not $fail_row.ok) "throw expr should fail"
assert ($ok_row.error | is-empty) "successful job should have empty error"
assert ($fail_row.error | str contains "removability-test-sentinel") "failed job should capture stderr"

print "all assertions passed"
