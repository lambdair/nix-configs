---
name: making-japanese-docs-readable
description: >
  日本語の設計文書・技術文書・調査ノート（Typst / HTML / Markdown）を「読みやすく書き直して」と言われたときに使う。
  「読みづらい」「話題がちらばっている」「注釈が細かすぎる」「アカデミックライティングの原則で」
  「構成を練り直して」「前提知識の解説が無い」「地の文を読みやすく」などのリクエストで発動する。
  構成レベル（Why/How 分離・節構成・前提知識の導入）を先に直し、文レベル（k16shikano の gist）をその上に当てる。
allowed-tools: Bash(jj *) Bash(bb *) Bash(python3 *) Read Grep Edit Write WebFetch
---

# 日本語文書を読みやすくする

「読みやすく」には 2 層ある。**構成レベルが先、文レベルは後**。文だけ直しても「話題がちらばる」「注釈が細かすぎる」は解けない。

| 層 | 直すもの | 規範 |
|---|---|---|
| 構成 | 節の並び、Why と How の分離、前提知識の導入、注釈・経緯の置き場 | 社内 設計ガイド（Why/How 分離）、Rust RFC テンプレート、Newcombe ら CACM 2015、Cedar 論文 §2、Gopen & Swan、木下是雄 |
| 文 | 段落・文の形、記号、語調 | k16shikano の gist 2 本（下記） |

## 0. 着手前

- `jj diff --stat` で現在のリビジョンを確認する。**文書は、それを追加したリビジョンで最終形にする**（後からの編集を積まない）。編集は先端に `jj new -m tmp` で一時リビジョンを作って行い、`jj squash -u --from @ --into <文書の初出リビジョン> <path>` で畳む。空になった一時リビジョンは `jj edit <先端>` で離れると消える。
- 古いリビジョンへ `jj edit` で移らない。当時の `.gitignore` に無いファイル（`.devenv/`、`lean/.lake/`、`devenv.local.nix` 等）がスナップショットに混入する。やむを得ず移るときは、それらを退避してから歩き、直後に `jj diff -r @ --stat` を確認する。
- 図・表・SVG・code・数値・引用は**内容を変えず位置だけ動かす**。事実の訂正が必要なら報告に明記する。
- 削るのではなく**移す**。移動先が無い経緯（訂正・当初の見積り・レビュー状況）は、spec や決定ログに既にあることを確認してから落とす。
- 大改修なら、まず診断と構成案を出してユーザーの確認を取る。

## 1. 診断（行番号付きで列挙する）

1. **未定義語**: 本文で使う専門語・固有名・記号（例: 適合検査、Cedar、2a/2b、Step 0、A 分類、commons、対照、シード）の初出行を出す。`check-first-use.bb` を使う（§4）。
2. **経緯・別案・実測ログが本流に混ざる箇所**: 「訂正」「当初は」「〜のはずだった」「却下した候補」「実測:」「レビュー状況」「初めて見えた」を grep。
3. **1 節に複数話題**: 見出しと本文の対応がずれている節、表が節の主題と違う節。
4. **注釈過多**: 括弧「（」の数、表セル内の注、kicker 付きボックスの数。括弧内に句点がある、または 2 つ以上の事柄を詰めた括弧は分解対象。
5. **見出し直下の副題**（「何を作り、何を言うか。」のような反問・予告の一行）と、タイトルと目次の間の要約文・タグ・リンク。
6. **文字列の節参照**: `grep -n '[0-9] 節' | grep -v '#ref'`。番号を振り直すと黙ってずれる。
7. **口語・原文の写し**: 「叩く」「identity」「spike」、オーナー指示の原文の「〜したい」「〜してもよい」がそのまま地の文に入っていないか。

## 2. 構成テンプレート

設計文書の完全形。文書の種類に応じて要らない節は落とすが、**順序と「本流に決定だけ」の原則は保つ**。

```
タイトル（h1 のみ。副題・タグ・リンクは置かない）
要旨（番号なし・目次に載せない abstract。論文の順で 5 段落: 背景と問題 → 手法の概念（提案が依拠する概念を、ツール名より先に定義する）→ 提案するもの → 主張できる範囲 → 結果。現在地や成功条件は書かない。数値は計測文書のものを引く）
目次（2 段。4.x 等の子項目も載せる）
1. 序論          Swales の CARS / SPJ の型。背景と混ぜない
   1.1 問題（要求の列挙 + なぜ難しいか + 対象範囲。成功条件や節目はロードマップへ）
   1.2 本設計の答え（中核の判断、問題と解の対応、貢献の箇条書きを節参照付きで）
   1.3 本文の構成（各節が何を述べるかを 1 段落）
2. 背景          予備知識。Cedar 論文の Overview、CACM の Precise Designs に当たる。冒頭に読者宣言 1 文（既知とする領域／本文で導入する語彙）
   2.1 対象システム（用語・構造・制約）
   2.2 これまでに分かっていること（先行文書の結果を 2〜3 文 + 表 1 本 + リンクに縮約。複製しない）
3. 合格の意味と範囲  出力の 4 値と合格の定義、「保証」の形（仮定・性質・範囲）、意味しないこと
4. 設計          How のみ。4.1 冒頭に Guide-level の一巡（既出の走行例で 仕様→実行→判定→出力 を半ページ）、以降 Reference-level
5. 保証しないこと  限界を 1 節に集約（CACM の "What Formal Specification Is Not Good For" 型）
6. ツール自身の検証
7. ロードマップ    図だけにせず、各段階を地の文で 1〜2 文ずつ書く
8. 未決とスコープ外（表）
9. 別案と根拠     表: 決定 | 根拠 | 退けた案（Rust RFC の Rationale and alternatives）
10. 先行例        Prior art。借りた構造と出所
11. 先行文書との関係
参照（ファイルへのポインタのみ）
```

定義の順序が節順と合わないときは節を入れ替える（例: 「土台」を使う表が「検査の3層」より前に出るなら 3 層の節を先に置く）。

## 3. ルール（決定事項）

**構成**
- 本流（設計節）には「今どうなっているか」だけ。根拠と退けた案は「別案と根拠」の表へ、限界は「保証しないこと」へ。
- **試行錯誤の変更履歴は載せない**。その判断の理由として外せない場合だけ、決定の根拠として書く。
- 前提知識は**読者宣言 + 初出定義**。用語集は作らない（重複するうえ初出前の使用を防げない）。
- Guide-level の走行例は**発明しない**。文書内で既に複数箇所に出ている操作・データを使う。
- 見出し直下の副題を付けない。節は最初の文が主張になる形で始める（重点先行・トピックセンテンス）。
- 各単位（文・段落・節）は 1 つの機能だけを持つ（Gopen & Swan）。段落内で話題が変わったら段落を分ける。

**文**（基礎層 japanese-tech-writing、その上に cognitive-rhythm-writing）
- 2 倍ダッシュ「——」と中黒「・」の並列は使わない（SVG・code・引用内の既存は触らない）。
- 太字は要所に絞る。「重要なのは」「要するに」「〜と言えるだろう」等の LLM 口調を使わない。ヘッジ（「〜と考えられる」等）は保護する。
- 括弧は減らす。理由・付随挙動は文に織り込む。残してよいのは短い定義グロス・条件式・先例ポインタ・表セル。
- 実装パス・関数名は本文に書かず責務で表す（設計文書の場合。研究ノートは可）。
- 口語・英語混じり・造語を標準語に: 叩く→呼び出す、identity→アイデンティティ、spike→試作、一級の概念→正式な概念、緑バッジ→合格。記法（〈操作 × アイデンティティ文脈〉、レベル1＝性質−期待値 等）は定義の場所にだけ残し、地の文では「操作とアイデンティティの組み合わせ」のように言い換える。
- 図注（caption）に本文を入れない。図注は図が何かの一文だけにし、説明は地の文へ。
- 先行例（Related Work / Prior art）は箇条書きではなく段落で、何を借りて何を変えたかを書く。箇条書きを使ってよいのは序論の要求・貢献・設計目標の列挙（Cedar 論文の貢献列挙、CACM の "1) … 2) …"）と手順の列挙に限る。
- 節を「A・B・C」のように 3 話題で束ねない。1 節 1 話題に分ける。
- 節番号を文字列で書かない（Typst なら `#ref(<label>)`）。番号を振り直したとき文字列の参照は黙ってずれる。

参照:
- cognitive-rhythm-writing: https://gist.github.com/k16shikano/eb2929f13ed19c97188393d297be8432
- japanese-tech-writing: 同作者の gist（`https://api.github.com/users/k16shikano/gists` の description "japanese-tech-writing/SKILL" から raw_url を取る）

## 4. 検証

書き直し後、次を機械的に確認する。

| 検査 | 方法 |
|---|---|
| 定義行 ≤ 初出行 | `bb ~/.claude/skills/making-japanese-docs-readable/check-first-use.bb <doc> <terms.edn>`。terms.edn は `{"用語" "定義行にだけ現れる正規表現"}` の map（`terms.example.edn` 参照）。タイトル・表セル直後の注・code 内・読者宣言で既知とした語は除外してよい |
| 相互参照 | 文字列の節参照が残っていないか（`grep -n '[0-9] 節' doc.typ \| grep -v '#ref'` が空）。HTML / Markdown なら参照先見出しが実在するか |
| 口語の残存 | `grep -n '叩\|identity\|spike\|一級' doc` がコードブロック以外で空 |
| 経緯語の残存 | `grep -c '当初\|訂正\|レビュー状況\|はずだった'` が 0 |
| 規範語彙の漏れ | `grep '緊張\|回収\|拍\|布石\|着地'` が 0（gist の語彙を本文に出さない） |
| Typst | `typst compile` が 0 エラー（相互参照の実在はコンパイルが肩代わりする）、`typstyle --check` が差分なし、`typst compile --format png --ppi 60 doc.typ 'page-{0p}.png'` で描画確認 |
| HTML | タグ整合（`python3` の `html.parser` で開閉を照合）、目次アンカーの実在、headless Chrome で描画（`"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --screenshot=... file://...`。Chrome 拡張が無くても動く） |

最後に `/self-review` を実行し、リビジョン説明に「移した先」と「完全に削除したもの」を書く。報告でも**移動と削除を分けて列挙**する。

## 参考元と借りたもの

| 参考元 | 借りたもの |
|---|---|
| 社内 Cosense「設計ガイド」（writing-design-docs skill 参照） | Why と How を混ぜない。経緯・別案は本流から出す |
| [Rust RFC テンプレート](https://raw.githubusercontent.com/rust-lang/rfcs/master/0000-template.md) | 節の骨格: Summary / Motivation / Guide-level → Reference-level / Drawbacks / Rationale and alternatives / Prior art / Unresolved questions |
| Newcombe ら「How Amazon Web Services Uses Formal Methods」CACM 2015（[DOI](https://dl.acm.org/doi/10.1145/2699417)、[preprint PDF](https://lamport.azurewebsites.net/tla/formal-methods-amazon.pdf)） | 限界と別案を独立した節に置く（"What Formal Specification Is Not Good For"、"Alternatives to TLA+"） |
| Cutler ら「Cedar: A New Language …」OOPSLA 2024（[arXiv](https://arxiv.org/abs/2403.04651)、[PDF](https://cdn.amazon.science/96/a8/1b427993481cbdf0ef2c8ca6db85/cedar-a-new-language-for-expressive-fast-safe-and-analyzable-authorization.pdf)） | §2 Overview が例題で概念を先に一巡する型。Introduction 末尾の貢献箇条書き |
| Gopen & Swan「The Science of Scientific Writing」（[PDF](https://www.usenix.org/sites/default/files/gopen_and_swan_science_of_scientific_writing.pdf)、[Crowl の要約](https://www.crowl.org/Lawrence/writing/GopenSwan90.html)） | 各単位（文・段落・節）は 1 つの機能。topic position に既知、stress position に新情報 |
| 木下是雄『理科系の作文技術』（[中公新書](https://www.chuko.co.jp/shinsho/1981/09/100624.html)、[要点](https://qiita.com/e99h2121/items/dd57fd2374d7e9e0726a)） | 重点先行、トピックセンテンス、無関係な文を同じ段落に入れない |
| Swales の CARS モデル（『Genre Analysis』1990）、[Simon Peyton Jones "How to write a great research paper"](https://www.microsoft.com/en-us/research/academic-program/write-great-research-paper/) | 序論の型: 問題 → 隙間 → 本文書がすること（貢献の箇条書き、節参照付き）→ 構成の案内 |
| k16shikano の gist 2 本（§3） | 文レベルの規範 |

見出しや節構成を引用するときは本文から取る。CACM の DOI ページと arXiv の要旨ページはメタデータしか無く、PDF は `uvx --from pypdf` で抽出した。

## よくある失敗

| 失敗 | 対策 |
|---|---|
| 文レベルだけ直して構成を触らない | 診断 §1 を先に出す。「話題がちらばる」は構成の欠陥 |
| 経緯を消して情報を失う | 移動先（spec・決定ログ・「別案と根拠」）を先に確認。削除は報告で明示 |
| 用語集で前提知識を済ませる | 読者宣言 + 初出定義。初出行チェックで機械的に確認 |
| 走行例を新しく作る | 文書内の既出の例を使う |
| 節番号を振り直して相互参照を壊す | 既存節への接ぎ木を優先。振り直したら相互参照を全件検証 |
| 副題・要約を番号付き節にする | 要約は番号なしの要旨として表題と目次の間に置く。リンクは末尾節 |
| WebFetch の要約モデルが見出しを捏造する | 参考文献は本文（PDF は `uvx --from pypdf`）から抽出して引用する |
| 形式変換（HTML→Typst 等）で本文を落とす | 変換前後のテキストを正規化して突き合わせ、欠落が見出し番号・相互参照・コード改行だけであることを機械的に示す |
| 古いリビジョンへ `jj edit` して ignore 前のファイルを混入させる | 一時リビジョン + `jj squash --into`。移るなら退避と `jj diff -r @ --stat` |
| オーナー指示の原文をそのまま要求節に写す | 口調が軽くなる。文語の要求文に直し、許可事項（「研究として作ってもよい」等）は書かない |
| 序論に成功条件や節目を書く | 序論に置くのは設計の前提になる範囲だけ。節目はロードマップへ |
