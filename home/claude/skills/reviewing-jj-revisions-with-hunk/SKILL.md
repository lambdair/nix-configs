---
name: reviewing-jj-revisions-with-hunk
description: Use when asked to review each revision or each hunk of a jj/git stack and leave per-hunk rationale comments in a live Hunk session — self-review before pushing a PR, annotating why each hunk changed, or walking a reviewer through a multi-commit stack revision by revision.
---

# Reviewing jj Revisions with Hunk

## Overview

Compose `jj` (the revision stack) with the `hunk session` CLI to verify every hunk of every revision and leave an attributable rationale comment on each, all persisted in one live Hunk session. Read diffs yourself with `jj show`; never drive the user's TUI with `hunk show`/`hunk diff`.

**REQUIRED BACKGROUND:** Read the `hunk-review` skill (`hunk skill path`) for the raw `hunk session` CLI. This skill layers a per-revision review workflow on top of it.

## The one gotcha that defines this workflow

Hunk stores inline comments by **(file, line, side), session-globally**. Reloading to another revision does **not** scope them: a comment on `input.clj:285` shows in *every* loaded revision whose diff covers that line. Multi-revision review of files that several revisions touch (very common) therefore **cross-contaminates** the view.

**Counter:** prefix every comment summary with `[<change-id>]` so each comment is attributable no matter which revision is loaded. There is no other reliable way to keep them straight in a single session.

Also: `hunk session comment clear --repo .` wipes **all** comments in the session, not just the loaded diff's.

## Workflow

1. **Confirm a live session.** `hunk session list --json`. Empty? Ask the user to launch `hunk show <rev>` (or `hunk diff`) **in a real terminal** — a `!`-prefixed / non-TTY invocation never registers with the daemon.
2. **Enumerate the stack.** `jj log -r 'trunk()..@ | @' --no-graph -T 'change_id.shortest(8) ++ " " ++ description.first_line() ++ "\n"'`.
3. **Read & verify each revision's diff yourself.** `jj show -r <id> --git`. Check each hunk is correct; grep the final state (`@`) for dangling references to symbols a revision deleted.
4. **Per revision, in stack order:**
   - `hunk session reload --repo . -- show <change-id>` — Hunk resolves jj revsets, so pass the **change-id** (stable; a mistyped commit-id prefix fails to resolve).
   - `hunk session review --repo . --json` — get per-file hunk structure. `hunkNumber` is **1-based** (= JSON `index` + 1).
   - Build a JSON batch and `hunk session comment apply --repo . --stdin`.
   - Verify the applied count.

Comment payload item: `{"filePath","hunkNumber","author","summary"}` — `summary` MUST start with `[<change-id>] `.

```bash
# Reapply a whole stack with attributable prefixes (zsh-safe loop):
printf '%s\n' "pznqxzmz pznq" "qzomsmys qzom" ... | while read -r cid f; do
  hunk session reload --repo . -- show "$cid" >/dev/null
  jq --arg p "[$cid] " '.comments |= map(.summary = $p + .summary)' "/tmp/claude/$f.json" \
    | hunk session comment apply --repo . --stdin
done
```

## hr — CLI helper (this skill ships one)

`hr` (a babashka script next to this SKILL.md) wraps the per-revision loop so the user doesn't type `hunk session ...` by hand. Invoke with `bb <path-to>/hr` (the skills dir isn't chmod-able, so don't rely on the exec bit; alias `hr='bb ~/.claude/skills/reviewing-jj-revisions-with-hunk/hr'`).

```
hr target <bookmark|revset>   # remember the review stack (uses trunk()..<target>)
hr list                       # index / change-id / commit / subject, base→tip
hr <n> | hr <change-id>       # reload the Hunk session to that revision
hr next | hr prev             # jump between commented hunks in the loaded diff
hr backup [dir]               # persist comments per revision; filters by [change-id] prefix to strip contamination
hr restore [dir]              # clear + re-apply from backup (idempotent; survives session loss)
```

Backups live in `~/.local/share/hunk-review/<repo>/comments/` (persistent, unlike /tmp). `hr backup` relies on the `[change-id]` summary prefix to keep only each revision's own comments — another reason the prefix convention is mandatory. **Run `hr backup` after a commenting session**: live comments are lost when the Hunk window closes, and `hr restore` is the one-command recovery.

## Quick reference

| Need | Command |
|------|---------|
| Detect session | `hunk session list --json` |
| Switch revision | `hunk session reload --repo . -- show <change-id>` |
| Hunk structure | `hunk session review --repo . --json` (jq `.review.files[] \| .hunks[]`) |
| Add one note | `hunk session comment add --repo . --file F --new-line N --summary "..."` (no `--hunk` here) |
| Add batch | `... | hunk session comment apply --repo . --stdin` (supports `hunkNumber`) |
| List (current diff) | `hunk session comment list --repo . --json` |
| Clear (whole session!) | `hunk session comment clear --repo . --yes` |

## Comment content

The user usually wants a note on **every** hunk. Honor that, but: put the real explanation on the first occurrence of a repeated pattern and keep the rest one line (`"同じ seam 置換"`). Flag cross-revision shape — e.g. a symbol added in rev 2 and **torn down in rev 7** — in both places (`【後続で巻き戻る】`). For a pushed-bookmark stack, note where the push boundary is: revisions above it are post-push review fixes (`jj new` layer), not squash candidates.

## Common mistakes

- **Driving the TUI:** running `hunk show`/`hunk diff` yourself hijacks the user's screen. Read with `jj show` instead.
- **No `[change-id]` prefix:** the single biggest failure — contaminated, unattributable comments across revisions.
- **Assuming reload scopes comments:** it doesn't (see the gotcha).
- **`for x in $var` in zsh:** doesn't word-split. Use `while read` over `printf '%s\n'`, or arrays.
- **Mistyped commit-id in `show`:** "could not resolve Jujutsu revset". Use change-ids.
- **Line-targeting a hunk-level note:** use `hunkNumber`, not `--new-line`, when the note is about the whole hunk.
