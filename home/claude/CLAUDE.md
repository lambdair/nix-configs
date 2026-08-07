# Personal Development Preferences

## 言語の使い分け — moonbit / zig / nushell / babashka

処理を書くときは bash/zsh の生スクリプトを避け、下のレイヤーで選ぶ。**上から順に**当てはめて最初に合致したものを使う:

| 言語 | レイヤー | 使いどころ | 判定の問い |
|---|---|---|---|
| **zig** | libc / カーネル / C | syscall・exec・C ライブラリ束縛の極小 native バイナリ | 「syscall/C の薄いラッパーか?」 |
| **nushell** (`nu -c '...'`) | シェル / パイプライン | 構造化データ（JSON/CSV/TOML）変換 + CLI 連携 + `par-each` 並列 | 「本質は "CLI を叩いて構造化出力を整形" か?」 |
| **babashka** (`bb -e` / `.bb`) | スクリプト / ロジック glue | 分岐ロジック + データ構造 + 成熟ライブラリが要る glue | 「ロジックはあるが起動コストは許容でき、ライブラリ即戦力が欲しいか?」 |
| **moonbit** | アプリ / 型付きロジック native | パーサ・アルゴリズム等の実ロジック。型・native 起動・検証が効く | 「型・native 起動・検証が効く実ロジックか?」 |

境界で迷ったときのタイブレーク（ここが実務の勝負どころ）:

- **zig vs moonbit**（共に native）: ロジックが無く C・syscall が主役 → **zig**。データモデリングや分岐に型が効く実ロジック → **moonbit**
- **nushell vs babashka**（共にスクリプト）: パイプ + 構造化変換が支配的 → **nushell**。分岐・データ構造・ライブラリ呼び出しが支配的 → **babashka**
- **babashka vs moonbit**（共にロジック）: 次のどれかが立てば **moonbit** —（1）頻繁起動でネイティブ起動が効く（2）規模・複雑さで静的型が効く（3）検証したい。どれも立たなければ **babashka**（使い捨て・即書き・成熟ライブラリ即戦力）

Read / Grep / Glob など専用ツールで済む読み取り・検索はそれらを優先する。nu/bb を使うのは「シェルでロジックを書く必要がある」場面に限る（単純なパイプや変数処理を生 bash で書かない、という趣旨）。

現リポジトリの実例: `home/jj-lock.zig`（zig: flock+exec シム）、`home/claude/skills/checking-removable-nix-workarounds/check-workarounds.nu`（nushell: nix build 並列）、`home/claude/hooks/*.bb`（babashka: フック）、`home/claude/statusline/`（moonbit: 頻繁起動する statusline）。

## Version Control — jujutsu (jj)

I use jujutsu (jj) instead of git. Always use `jj` commands, never `git` commands.
Reference: https://github.com/jj-vcs/jj

### Core Rules

- **リビジョン規律**: ファイル編集前に `jj diff --stat` で現在のリビジョンの状態を確認し、無関係な変更を混入させないこと。1リビジョン = 1論理変更。レビュアビリティを最優先で分割する。変更が概ね150行を超える場合は意味のある単位での分割を検討する。詳細は `~/.claude/rules/revision-discipline.md` 参照。
- 修正を行う際は、明確な指示がない限り `jj edit` で過去のリビジョンを編集する形で行う。ただし、構造が大きく変わる場合は実行前に確認を取ること。
- **編集後に @ を戻さない**: `jj edit` での編集が終わっても、元居たリビジョンへ `jj edit` で戻らない。working copy を入れ替えるたびにファイルが書き換わり、常駐プロセス（REPL 等）が壊れるため。次の作業が別のリビジョンを要求したときにだけ移動する。詳細は `~/.claude/rules/revision-discipline.md` 参照。
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
