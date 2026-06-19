# jj Workflow Patterns

## Revision Operations

### squash — 親リビジョンに統合
```bash
jj squash                    # 現在の変更を親に統合
jj squash -r REV             # 指定リビジョンを親に統合
jj squash --into REV         # 指定リビジョンに統合
jj squash -i                 # インタラクティブに部分統合
```
**使い分け**: WIP コミットの整理、細かすぎるリビジョンの統合に使用。

### split — リビジョンの分割
```bash
jj split                     # 現在のリビジョンをインタラクティブに分割
jj split -r REV              # 指定リビジョンを分割
jj split PATH                # 指定パスのファイルで分割
```
**使い分け**: 一つのリビジョンに複数の論理変更が入っている場合に使用。レビュー前に積極的に使うこと。

### absorb — 自動的に変更を振り分け
```bash
jj absorb                    # WC の変更を適切な祖先リビジョンに自動配布
```
**使い分け**: 複数リビジョンにまたがる修正（lint fix, typo fix 等）を一括で正しいリビジョンに配布。`jj edit` で個別に直すより効率的な場合に使用。

### rebase — リビジョンの移動
```bash
jj rebase -r REV -d DEST       # 単一リビジョンを移動（子は元の場所に残る）
jj rebase -s REV -d DEST       # リビジョンとその子孫を移動
jj rebase -b REV -d DEST       # ブランチ全体を移動
jj rebase -r REV -A AFTER      # AFTER の後に挿入（--insert-after）
jj rebase -r REV -B BEFORE     # BEFORE の前に挿入（--insert-before）
```

### describe — メッセージ編集
```bash
jj describe                     # 現在のリビジョンのメッセージを編集
jj describe -r REV              # 指定リビジョンのメッセージを編集
jj describe -m "message"        # メッセージを直接指定
jj describe -r REV -m "message" # 指定リビジョンにメッセージを直接指定
```

## Parallel Work with Workspaces

### 基本パターン
```bash
# 別機能の作業を並行して行う
jj workspace add ../project-feature-x
cd ../project-feature-x
jj new main -m "feature X"

# 元のワークスペースに戻る
cd ../project
jj workspace update-stale  # 他のワークスペースの変更を反映
```

### ワークスペースの管理
```bash
jj workspace list              # ワークスペース一覧
jj workspace forget <name>     # ワークスペース削除（リビジョンは残る）
```

**注意**: ワークスペースは同じリポジトリを共有するため、`jj git fetch` はどちらからでも一度だけ実行すれば良い。

## Megamerges (複数 branch の並行開発)

進行中の複数 branch を octopus merge で束ね、その上で作業する手法。複数機能を同時に開発し、相互作用を一つの working copy で検証したい場合に有効。
参考: https://isaaccorbrey.com/notes/jujutsu-megamerges-for-fun-and-profit

### 基本フロー
```bash
# 各 feature branch の先端を親として megamerge を作成
jj new feature-a feature-b feature-c -m "megamerge"

# megamerge の上に空リビジョンを重ねて作業
jj new -m "wip"

# 編集後、変更を該当 branch に振り分け
jj absorb                              # 自動振り分け（推奨）
jj squash --into feature-a -i          # 手動で特定 branch に統合

# trunk の更新に追従
jj rebase -d trunk()                   # megamerge と子孫を最新 trunk に
```

### 使い分け
- **2 並列まで・独立性が高い**: `jj workspace` のほうが軽量で衝突も起きにくい
- **3 つ以上の branch を行き来する / 相互作用をテストしたい**: megamerges
- **branch 間で共通の修正を入れたい**: megamerge 上で編集 → `jj absorb` で各 branch に配布

### 重要な禁則・整合ルール
- **megamerge リビジョン自体を push しない**。push は個別の feature branch（bookmark）に対してのみ行う:
  ```bash
  jj git push -b feature-a             # 個別 branch のみ push
  ```
- megamerge 上での編集は WIP に過ぎない。push する前に **必ず `jj absorb` または `jj squash --into` で該当の論理 branch に移す**（`revision-discipline.md` の「1リビジョン=1論理変更」原則を維持するため）。
- push 済みの feature branch を編集する場合は、megamerge 上で編集してから配布しても、最終的な push 規律（force push 可否）は通常通り `revision-discipline.md` に従う。
- megamerge の親が増減した場合は再作成する: `jj abandon` で古い megamerge を捨て、新しい親集合で `jj new` し直す。

## Conflict Resolution

### コンフリクトが発生した場合
```bash
jj status                      # コンフリクトファイルを確認
jj diff                        # コンフリクトの内容を確認
# ファイルを編集してコンフリクトマーカーを解消
jj squash                      # または jj describe で完了
```

jj はコンフリクトをファーストクラスで扱う。コンフリクト状態でもコミットは可能で、後から解消できる。

### rebase 時のコンフリクト
```bash
jj rebase -d main@origin       # コンフリクトが発生する可能性
jj log                         # コンフリクトのあるリビジョンに × マーク
jj edit REV                    # コンフリクトリビジョンに移動
# 解消してから次のリビジョンへ
```

## Common Mistakes and Avoidance

### 1. 空リビジョンの放置
`jj new` で作った空リビジョンが溜まりがち。`jj abandon` で整理する。
```bash
jj abandon REV                 # 不要なリビジョンを削除
```

### 2. Working copy の変更を意図せず失う
`jj edit` で別リビジョンに移動すると、現在の WC 変更はそのリビジョンに残る。
移動前に `jj status` で確認すること。

### 3. bookmark の付け忘れ
push する前に bookmark を設定する必要がある。
```bash
jj bookmark create BRANCH -r REV   # ブックマーク作成
jj bookmark set BRANCH -r REV      # ブックマーク移動
jj bookmark list                    # 一覧確認
```

## Git Interop

```bash
jj git fetch                       # リモートから取得
jj git push                        # push
jj git push -b BOOKMARK            # 特定ブックマークのみ push
jj git push --change REV           # リビジョンから自動的にブックマーク作成して push
```
