#!/usr/bin/env bash
# betterleaks secret-scan guard wrapping the real `jj` binary.
#
# Why wrap the binary instead of using a hook or a shell alias:
#   - jj runs NO git hooks (neither pre-commit nor pre-push), so secret
#     scanners wired as pre-commit/pre-push hooks never fire on a jj workflow.
#   - TUIs such as jjui / lazyjj exec `jj git push ...` as a subprocess, so a
#     nushell function or alias would not be triggered by them either.
# Wrapping `jj` itself is the only point that gates every push path
# (CLI, jjui, lazyjj, scripts, agents) before secrets leave the machine.
#
# betterleaks (the Gitleaks successor) shares the gitleaks CLI surface:
# `git`/`dir` subcommands and --log-opts / --no-banner / --redact / --exit-code.
#
# @jj@ and @betterleaks@ are substituted with absolute store paths at build time.
set -euo pipefail

real_jj="@jj@"
betterleaks="@betterleaks@"

# Detect an adjacent `git push` subcommand anywhere in the argument list
# (jjui invokes e.g. `jj git push --remote origin`).
is_push=0
prev=""
for a in "$@"; do
  if [ "$prev" = "git" ] && [ "$a" = "push" ]; then
    is_push=1
    break
  fi
  prev="$a"
done

if [ "$is_push" -eq 1 ]; then
  repo="$("$real_jj" root 2>/dev/null || true)"
  [ -n "$repo" ] || repo="$PWD"
  echo "🔍 betterleaks: scanning for secrets before push (${repo}) ..." >&2

  if [ -d "$repo/.git" ]; then
    # Colocated repo: scan exactly the local-only commits — those reachable
    # from a local branch (bookmark) but not from a remote-tracking ref —
    # i.e. precisely what this push would publish. Git mode ignores untracked
    # / .gitignored files, so node_modules and friends are never scanned.
    #
    # Use --branches, NOT --all: jj keeps tens of thousands of refs/jj/ keep-
    # refs in a colocated repo, and --all would walk every one of them
    # (abandoned / hidden commits included), making the scan effectively never
    # finish. --branches limits the walk to refs/heads/* — the local bookmarks
    # jj exports — which is the real push scope.
    if ! "$betterleaks" git --no-banner --redact \
      --log-opts="--branches --not --remotes" "$repo" >&2; then
      echo "🚫 betterleaks found potential secrets — push aborted." >&2
      echo "   Amend/remove them with jj before pushing, or run the real jj at" >&2
      echo "   ${real_jj} to bypass intentionally." >&2
      exit 1
    fi
  else
    # Non-colocated repo (no .git): fall back to scanning the working tree.
    if ! "$betterleaks" dir --no-banner --redact "$repo" >&2; then
      echo "🚫 betterleaks found potential secrets — push aborted." >&2
      echo "   Amend/remove them with jj before pushing, or run the real jj at" >&2
      echo "   ${real_jj} to bypass intentionally." >&2
      exit 1
    fi
  fi
  echo "✅ betterleaks: no secrets detected. Pushing ..." >&2
fi

exec "$real_jj" "$@"
