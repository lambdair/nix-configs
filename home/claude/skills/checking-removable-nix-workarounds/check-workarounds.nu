#!/usr/bin/env nu
# Parallel nix-build runner for removability checks.
#
# Input  (stdin, JSON): [{ label: string, expr: string }, ...]
#   - expr is a Nix expression string; build is run with --impure so it may
#     reference the local flake (builtins.getFlake (toString ./.)) and repo paths.
# Output (stdout, JSON): [{ label: string, ok: bool, error: string }, ...]
#   - ok   = true when `nix build` exits 0 (the workaround target builds cleanly)
#   - error = trimmed stderr when ok is false, otherwise ""
#
# Run jobs from the repo root so relative paths in exprs resolve.

def run-job [job: record] {
  let result = (^nix build --no-link --impure --expr $job.expr | complete)
  {
    label: $job.label
    ok: ($result.exit_code == 0)
    error: (if $result.exit_code == 0 { "" } else { $result.stderr | str trim })
  }
}

def main [] {
  # nushell 0.113.0: `$in` inside `def main []` is `nothing` when the script is
  # invoked as `nu script.nu` with piped stdin, so read stdin via `^cat`.
  ^cat
  | from json
  | par-each { |job| run-job $job }
  | to json
}
