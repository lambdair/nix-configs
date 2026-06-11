---
name: create-pr
description: Create a GitHub pull request with jj (jujutsu). Use this skill only if explicit command.
allowed-tools: Bash(jj *) Bash(gh *)
disable-model-invocation: true
---

# Create Pull Request (jj)

このリポジトリは jujutsu (jj) を使う。git コマンドは使わない。

## 現在の変更をリビジョンに分割する
現在のタスクの内容を、わかりやすく **細かい** 単位のリビジョンに分割する。
すべての変更を1リビジョンにまとめると読みづらいので適切に分割すること（`jj split` を活用）。
trunk (`trunk()` / `main`) 上に直接いる場合は、PR 用に新しいリビジョン列を作るか確認すること。
ブランチ(bookmark)名は "feature/", "chore/" のような prefix は不要。
わかりやすい単位の例:
- DBの操作の entity ファイルに1関数を追加 & それのテストをまとめて1リビジョン

また、リポジトリの状態によってはタスクに関係ない diff が別リビジョンに含まれていることがあるが、誤って PR に混ぜないように注意して作業する。

jj では作業コピーも常にリビジョンなので「未コミット」の概念はない。代わりに、各リビジョンが1論理変更になっているか・description が適切かを確認する。粒度が悪かったり、レビューしづらい構成(後のリビジョンで前を修正するなど)の場合は `jj squash` / `jj split` / `jj rebase` でリビジョンを再構成することをユーザーに提案すること。

## bookmark を作成して push する
PR にする範囲の先端リビジョンに bookmark を作成する:
```
jj bookmark create <name> -r <rev>
```
そのうえで push する:
```
jj git push -b <name>
```
**push はユーザーの負担になる破壊的操作のため、グローバル規約に従い、push 直前に必ずユーザーへ確認を取る。** このスキル自体が `/create-pr` で明示起動された場合でも、push 対象 bookmark とリビジョン列を提示してから実行する。

## Pull Request を作成する
`gh pr create` で**必ず draft 状態**で作成する。
リポジトリ内のテンプレートにしたがって日本語で作成する。
内容はなるべく簡潔になることを目指すがレビューに必要な情報は含める。
PRを読む上での注意点(そのリポジトリの開発者であっても知らない可能性のある必要な前提知識など)は明記する。

## その後の追加作業時
同タスク内で修正を行ったあと、勝手に `jj git push` は行わない。
ユーザーの指示があるまで絶対に `jj git push` や Pull Request の更新は行わない。
