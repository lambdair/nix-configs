---
name: self-review
description: Review your own unpushed jj revisions — implementation soundness, comment policy, revision split — and record the result so the push gate opens. Use when a task is finished, when a push was blocked by the self-review gate, or on request ("レビューして", "自己レビュー").
allowed-tools: Bash(jj *) Bash(bb *) Bash(just *) Read Grep
---

# 自己レビュー

未 push のリビジョンを、他人のコードを見るつもりで読む。「書いたときに正しいと思った」ことは根拠にならない。

## 1. 対象を列挙する

```
jj log -r 'remote_bookmarks()..@' --no-graph -T 'change_id.short() ++ " " ++ description.first_line() ++ "\n"'
```

## 2. リビジョンごとに diff を読む

```
jj diff -r <change-id> --git
```

見るもの:

**実装の妥当性**
- 依頼された範囲を満たしているか。広げすぎ・狭めすぎていないか
- 既存の関数・設定を再実装していないか（同じことをしている箇所を Grep で探す）
- 壊れやすい前提を持ち込んでいないか（引数リストの手書き、ハードコードしたパス、上流の出力形式への依存）
- 失敗したときにどうなるか。握り潰していないか

**コメント方針**
- 現状の簡潔な説明になっているか
- 経緯・不採用案・ベンチマーク数値が残っていないか（それらはコミットメッセージか PR 説明に書く）
- 既存ファイルの言語と粒度に合っているか
- そのファイル固有の規約に従っているか（例: `home/default.nix` は全エントリに一行説明）

**リビジョン規律**
- 1リビジョン = 1論理変更か。「ついでの修正」が混ざっていないか
- 上から順に読めるか。後のリビジョンで前を打ち消していないか
- description はプロジェクトの慣習どおりか

**検証**
- lint / format / テスト / ビルドを実際に走らせたか。走らせていないなら走らせる

## 3. 指摘を処理する

直せるものは直す。直さないと決めたものは、なぜ直さないかをユーザーに報告する。黙って見送らない。

修正先は `~/.claude/rules/revision-discipline.md` に従う（未 push なら該当リビジョンを直接編集、push 済みなら新しいリビジョンを積む）。

## 4. 記録する

レビューしたリビジョンごとに記録する。所見が空では記録できない。

```
bb ~/.claude/hooks/self-review-gate.bb --mark <change-id> "<一行の所見>"
```

所見には「何を見たか」を書く（例: `comment policy + error path checked`）。記録は diff のハッシュで照合するので、記録後に内容を変えれば無効になり、再度 mark が必要になる。

## 5. 報告してから push する

レビュー結果（直した指摘・見送った指摘）をユーザーに伝え、push の可否を確認する。記録がないリビジョンを含む push はフックがブロックする。
