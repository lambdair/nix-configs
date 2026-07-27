# jj megamerge ワークフロー

複数の feature branch を octopus merge で束ねた megamerge を、コマンド一発で再構築・develop 追従する仕組み。

## 前提

- 束ねたい feature branch には bookmark を付ける。`wip/` のような prefix は不要で、`auth-refactor` のような**素のブランチ名**でよい（そのまま push すれば PR ブランチになる）。`wip()` は名前ではなく「trunk に未マージの自分の bookmark」という状態で対象を検出する
- megamerge に含めたくない退避ブランチがある場合は `JJ_MEGAMERGE_WIP` で対象 revset を明示的に絞る（「使い方」参照）
- develop 中心のリポジトリでは `.jj/repo/config.toml` で `revset-aliases.'trunk()' = 'develop@origin'` と上書きする

## 使い方

### CLI から

```bash
# fetch + rebuild
jj-megamerge-rebuild

# fetch 省略
JJ_MEGAMERGE_FETCH=0 jj-megamerge-rebuild

# trunk を develop@origin に固定
JJ_MEGAMERGE_TRUNK=develop@origin jj-megamerge-rebuild

# wip 対象 revset を上書き（特定ブランチだけ束ねる等、対象を絞りたいとき）
JJ_MEGAMERGE_WIP='bookmarks(glob:"feature/*") & mine()' jj-megamerge-rebuild
```

### jjui から

| key | 動作 |
|-----|------|
| `m` | `jj-megamerge-rebuild`（fetch なし） |
| `F` | `jj git fetch` + `jj-megamerge-rebuild` |

## 提供される revset-aliases

`home/jj-megamerge.nix` で home-manager 経由で配布される:

| alias | 定義 | 用途 |
|-------|------|------|
| `wip()` | `bookmarks() & mine() ~ ::trunk() ~ mm()` | 自分の作業中 feature branch（trunk 未マージの自分の bookmark。megamerge 自身は除外） |
| `mm()` | `subject(exact:"megamerge") & mine() ~ ::trunk()` | 現在の megamerge リビジョン |

注: `mm()` は `description` ではなく `subject` で照合する。jj は description の末尾に改行を付けて保存するため、`description(exact:"megamerge")` は一致しない。`subject` は description の 1 行目のみを見るため正しく動作する。

## 受け入れチェック

新環境で動作確認するときの手順:

1. `test-1`, `test-2` bookmark を作って `jj-megamerge-rebuild` → 親が3つ（trunk + 2 wip）の megamerge ができる
2. もう一度実行 → 同じ megamerge change_id が維持される（in-place rebase）
3. `test-3` を追加して実行 → 親が4つになり change_id は維持される
4. `test-1` の bookmark を削除して実行 → 親が3つに減り change_id は維持される
5. jjui を起動して `m` キー → 同じ結果になる

## 設計メモ

実装上の要点:

- `description(exact:"megamerge")` ではなく `subject(exact:"megamerge")` で照合する（jj は description 末尾に改行を付けるため `description` の完全一致は効かない）
- jjui キーは `F`（jjui の key 表記は単一文字）
- `wip()` は `wip/*` prefix ではなく「trunk 未マージの自分の bookmark」という状態で対象を検出する。push 時に prefix を外す手間をなくし、素のブランチ名のまま PR に使えるようにするため
