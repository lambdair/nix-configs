---
name: pr-inline-comments
description: 'Use when writing or updating a PR description, or right after pushing/creating a PR, and some of the explanation is tied to specific lines or hunks rather than the whole change — e.g. なぜこの分岐にしたか, ついで修正の理由, 非自明な選択, ワークアラウンドの背景, 既存挙動との差, 再現手順やスクショ付きの補足. Those belong as inline review comments at the exact location, NOT buried in the PR body. Triggers: "PRの説明を書いて/直して", "PRに解説を追加", "行ごとの背景を残したい", "self-review コメント", "インラインコメントで説明", reviewing your own diff before requesting review.'
---

## 何のためのスキルか

PR の説明には2種類ある。**全体の説明**（何を・なぜ・どう読むか）と、**行/hunk 固有の説明**（なぜこの分岐、なぜこのついで修正、非自明な選択の理由）。後者を PR 本文に列挙すると、レビュアーは差分と本文を往復することになり読みにくい。**該当箇所にインラインコメントを置けば、レビュー UI 上でコードのすぐ隣に説明が出る。**

良い実践の形: 作者自身が、なぜこの分岐にしたか・なぜ既存の挙動を変えたか（再現動画付き）・なぜこの初期化方法かといった rationale を、それぞれ**該当行のインラインコメント**として残す。PR 本文は高レベルに保つ。

## 説明の置き場所を分ける

| 置き場所 | 書く内容 |
|---|---|
| **PR 本文** | 全体の what / 設計判断の why（設計 issue・Figma へのリンク）/ 読み方（リビジョン構成・推奨レビュー順） |
| **インラインコメント** | 行・hunk 固有の rationale。「コードを読んだ人がここで疑問を持つだろう」という箇所に、その場で答える |

**判断基準**: その説明が特定の行を指しているなら → インラインコメント。差分全体・複数箇所にまたがる方針なら → 本文。本文に「`foo.clj:42` の分岐は〜」のように行を名指しする説明を書きそうになったら、それはインラインコメントにすべきサイン。

インラインコメント向きの典型:
- なぜこの分岐 / この実装方法を選んだか（他の自明な選択肢を採らなかった理由）
- 「ついで修正」の理由と影響範囲（理想は別リビジョンだが hotfix としてまとめた、等。[[revision-discipline]] 参照）
- ワークアラウンド・暫定対応の背景と、本来あるべき姿
- 既存挙動との差、後続 PR への布石
- 挙動変更・バグ修正の**再現手順／スクリーンショット／動画**

## 短く書く

インラインコメントは**コードから復元できないことだけ**を書く。差分はレビュー UI のすぐ隣に出ているし、ソースコメントも一緒に読まれる。重複した説明は、レビュアーに同じことを二度読ませるだけになる。

書かない:
- コードを見れば分かること。クラス名・定数・値そのものの再掲
- **すぐ上のソースコメントが既に書いていること**。コード側に「なぜこの方式が必要か」を書いたなら、インラインで再説明しない
- 値の一覧表。値はコードにある。書くならどう導かれたか

書く:
- なぜ他の自明な選択肢を採らなかったか
- どういう条件で壊れるか、何を変えたら見直しが要るか
- 定数・マジックナンバーの**導出方法**。コードには結果しか残らない
- この PR の外にある事情。別リポの制約、依頼の経緯、既存の運用など

ソースコメントとインラインコメントで同じ文が書けてしまうなら、どちらかに寄せるサイン。コードの「今どうあるか」はソースコメント、「なぜそうしたか・何を捨てたか」はインラインコメント。

## PR の外を指すときは permalink を貼る

別リポジトリ・ライブラリ・過去のコミットを根拠にするなら、レビュアーがその場で確認できるよう SHA 固定の permalink を貼る。ライブラリなら**実際に依存しているバージョンのタグの SHA** を使う。main を指すと、そのコードが今見ているものとずれる。

```bash
# 依存バージョンのタグ SHA
gh api repos/<owner>/<repo>/tags --jq '.[] | select(.name == "v1.2.3") | .commit.sha'
# その SHA で行番号を確認
gh api "repos/<owner>/<repo>/contents/<path>?ref=<sha>" --jq '.content' | base64 -d | grep -n '<検索語>'
```

→ `https://github.com/<owner>/<repo>/blob/<sha>/<path>#L<行>`

## 手順

1. 差分を確認し、レビュアーが疑問を持ちそうな非自明な箇所を列挙する
2. 各箇所を「本文 or インラインコメント」に振り分ける（上の判断基準）
3. 各コメントについて、コードとソースコメントを読んで分かることを削る（「短く書く」参照）
4. owner / repo / PR番号 / head SHA を取得する
5. 1件なら単一コメント、複数なら review として一括投稿する
6. 投稿後、PR の URL を報告する

## 投稿コマンド

メタ情報を取得:

```bash
gh pr view <PR番号> --json number,headRefOid,headRepositoryOwner,headRepository \
  -q '{owner: .headRepositoryOwner.login, repo: .headRepository.name, sha: .headRefOid}'
```

**複数コメントを1つの review として一括投稿（推奨）** — 日本語・複数行・permalink を含むため、JSON はファイルに書いて `--input` で渡す（bash のクォート事故を避ける）。`comments[].line` は差分に現れる**新側の行番号**、複数行レンジは `start_line`＋`line`：

```jsonc
// /tmp/claude/pr-review.json として Write ツールで作成
{
  "event": "COMMENT",
  "comments": [
    { "path": "src/core/validation.ext", "line": 45, "side": "RIGHT",
      "body": "入力が空のときループを無駄に回さないための早期 return。レビュー指摘 #1234 への対応。" },
    { "path": "src/hooks/form.ext", "start_line": 71, "line": 77, "side": "RIGHT",
      "body": "onBlur だと変更が検知されずバリデーションエラーが消えないバグがあり、ついでに onChange に変更。\nhttps://github.com/<owner>/<repo>/blob/<sha>/src/hooks/form.ext#L71" }
  ]
}
```

```bash
gh api repos/<owner>/<repo>/pulls/<PR番号>/reviews --input /tmp/claude/pr-review.json
```

**1件だけなら単一コメントエンドポイント:**

```bash
gh api repos/<owner>/<repo>/pulls/<PR番号>/comments \
  -f body='…説明…' -f commit_id='<sha>' -f path='path/to/file' -F line=42 -f side=RIGHT
```

## 注意

- **変更行にしかコメントできない**。差分に含まれない行を指定すると 422。説明したい対象が未変更行なら、最も近い変更行に紐づけるか、本文／通常コメントにする。
- `side`: `RIGHT` = 変更後（通常こちら）、`LEFT` = 変更前。
- 複数行レンジは `start_line`（始点）＋ `line`（終点）、両方 `side` を揃える。
- 自分の PR への review は `event` を **`COMMENT`** にする（`APPROVE`/`REQUEST_CHANGES` は自分の PR には付けられない）。
- permalink はブランチ名でなく **コミット SHA** で貼る（後から行がずれない）。
- 投稿は外向きアクションなので、内容を一度ユーザーに見せてから投稿してよいか確認する（明確な投稿指示がある場合を除く）。

## 関連

- PR 本文の書き方・テンプレートはプロジェクト規約に従う（`.github/pull_request_template.md` があればそれに沿う）。
- 自己レビューで指摘事項を洗い出す場合は [[diff-review]] と併用する。
