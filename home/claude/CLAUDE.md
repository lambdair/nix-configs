# Personal Development Preferences

## Shell Execution — nushell / babashka

シェルで処理を実行する際は bash/zsh の生スクリプトを避け、nushell か babashka を使う。用途で使い分ける:

- **nushell (`nu -c '...'`)**: データ処理・パイプライン・構造化データ（JSON/CSV/TOML 等）の操作・ファイル操作
- **babashka (`bb -e '...'` または `.bb` スクリプト)**: 複雑なロジック・構造化された処理。既存のフック類・statusline は全て babashka で書かれている

ただし Read / Grep / Glob など専用ツールで済むファイル読み取り・検索は従来通りそれらを優先する。nu/bb を使うのは「シェルでロジックを書く必要がある」場面に限る（単純なパイプや変数処理を生 bash で書かない、という趣旨）。

## Version Control — jujutsu (jj)

I use jujutsu (jj) instead of git. Always use `jj` commands, never `git` commands.
Reference: https://github.com/jj-vcs/jj

### Core Rules

- **リビジョン規律**: ファイル編集前に `jj diff --stat` で現在のリビジョンの状態を確認し、無関係な変更を混入させないこと。1リビジョン = 1論理変更。レビュアビリティを最優先で分割する。変更が概ね150行を超える場合は意味のある単位での分割を検討する。詳細は `~/.claude/rules/revision-discipline.md` 参照。
- 修正を行う際は、明確な指示がない限り `jj edit` で過去のリビジョンを編集する形で行う。ただし、構造が大きく変わる場合は実行前に確認を取ること。
- **push済みリビジョンの保護**: `jj log` で対象リビジョンが push 済みか確認し、push 済みかつ人間のレビュアーがいる場合は `jj edit` ではなく `jj new` で新しいリビジョンを作成して修正する。bot（copilot, devin 等）のみがレビュアーの場合は force push してよい。

### Command Mapping (git → jj)

| git | jj | Notes |
|-----|-----|-------|
| `git status` | `jj status` | |
| `git diff` | `jj diff --git` | `--git` for unified format |
| `git log` | `jj log` | Shows revision graph |
| `git log -p` | `jj log -p` | With patch |
| `git commit` | `jj commit -m "msg"` | Working copy → new revision |
| `git commit --amend` | `jj describe -m "msg"` | Edit current revision message |
| `git add -p && git commit` | `jj split` | Interactively split changes |
| `git rebase -i` (squash) | `jj squash` | Squash into parent |
| `git rebase --onto` | `jj rebase -r REV -d DEST` | Move revisions |
| `git stash` | `jj new` | Just start a new revision |
| `git push` | `jj git push` | |
| `git pull` | `jj git fetch && jj rebase -d main@origin` | |
| `git checkout -b` | `jj new -m "msg"` then `jj bookmark create` | |
| `git branch` | `jj bookmark list` | |
| `git cherry-pick` | `jj new REV` or `jj rebase` | |
| `git revert` | `jj revert -r REV -A @` | Apply reverse as a new commit |
| N/A | `jj absorb` | Auto-distribute fixups to relevant revisions |
| N/A | `jj undo` / `jj op restore <OP>` | Undo last operation / restore to an operation |
| N/A | `jj evolog` | History of how a single change evolved |

### Revset Quick Reference

```
@           Current working copy
@-          Parent of working copy
@--         Grandparent
REV-        Parent of REV
REV+        Children of REV
x::y        DAG range from x to y (inclusive)
x..y        x::y excluding x
::x         Ancestors of x
x::         Descendants of x
trunk()     Main branch tip
mine()      Revisions authored by me
bookmarks() All bookmark revisions
description(pattern)  Search commit messages
```

### Workspace (Parallel Work)

```bash
jj workspace add ../project-feature  # Create parallel workspace
jj workspace list                     # List all workspaces
jj workspace forget <name>            # Remove workspace
```

Each workspace has its own working copy but shares the same repo.

### Revision Notation in Conversations

- `r:xxx` or `rev:xxx` — indicates a jj revision
- Examples: `r:abc123`, `rev:@-`, `r:main`

## Detailed Workflows

See `~/.claude/rules/jj-workflow.md` for detailed jj workflow patterns.
See `~/.claude/rules/coding-preferences.md` for cross-project coding preferences.
