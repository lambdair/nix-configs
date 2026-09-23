---
name: creating-heptabase-explainer-note
description: 'Use when the user wants the mechanism behind something explained and kept in Heptabase — a math or logic concept, a protocol, an algorithm, a format, anything whose workings do not fit the one-sentence concept card. Triggered by "仕組みを詳しく", "わかりやすくまとめて", "図や数式で説明して", "もっと詳しい解説", by a follow-up question about a card just created, or when a card just made leaves an obvious "but how does it actually work" gap the user would want filled. This is the sister skill of creating-heptabase-concept-card: the card is the one-sentence index entry, this note is the explanation. Skip for answers that stay in chat and for edits to existing notes.'
---
## Overview

The user keeps a Japanese knowledge graph in Heptabase. `creating-heptabase-concept-card` writes the one-sentence entry: what a thing *is*. That format deliberately excludes diagrams, math, headings and second sentences, so it cannot carry *how a thing works*. This skill writes the companion note that can — with Mermaid diagrams and KaTeX math where they earn their place — and keeps it short enough to be read in one sitting.

Working exemplar in the workspace: `FIDO2の仕組み`, id `d3b2ada3-a5ee-476c-9700-2df3647f05a4`. Read it with `heptabase note read` before writing; it shows the shape faster than this file describes it.

**REQUIRED SUB-SKILL:** `heptabase:heptabase-cli` for the commands and their current flags.

## 1. Find what the graph already has

The note is worth little if it floats. Before writing, look for the topic's concept card and any older note on it:

```
heptabase card list -q "<日本語名>" --card-types note --limit 100
heptabase card list -q "<English name>" --card-types note --limit 100
```

`-q` is a fuzzy full-text filter ordered by last edit, and it misses things: `-q "ユニフィケーション"` and `-q "単一化"` both failed to surface the workspace's own `unification` note. Try the English name, an ingredient or sub-term, and a distinctive word you expect in the body before concluding nothing exists.

- **A concept card exists** → mention it on the note's first paragraph and take the note's tags and whiteboard from it (`heptabase card properties <cardId>`), so the pair sits together.
- **Only an older note exists** → mention that instead and reuse its tags.
- **Nothing exists** → that is fine and common. Open with the core sentence alone, and derive tags from the subject the way the sister skill's step 5 does. Do not invent a concept card unless the user wants one; if the topic clearly deserves the index entry too, say so in the report and let them ask.

## 2. What the note is

- **Title:** the H1 — `note create` takes the title from the first line, so the file starts `# FIDO2の仕組み`. Plain, not bold: `# **Title**` is the concept-card marker. Bare and descriptive (`〜の仕組み`), no half-width parens (concept cards) and no full-width `（）` (the user's LaTeX definition notes). The title names a *topic*, not a term.
- **Lead paragraph:** the card mention plus the single most important sentence of the note. If the reader stops there they should still have the key idea.
- **Created by AI stays on** — omit `--no-created-by-ai`. Concept cards opt out because the user supplies the fact and you only transcribe it. An explainer is your exposition even when the user asked for it kept, and leaving the mark lets them filter it in Card Library; the decision is settled here, so there is no need to re-read `references/created-by-ai.md` for it. If they say the note is theirs to own, pass the flag — the mark cannot be changed after create.

## 3. Concision is the whole job

A long explanation is the easy failure, and it is what the user objects to. The first FIDO2 explainer had six sections, three diagrams, two formulas — the flowchart repeated the bullet list above it, the `Verify` formula restated the `Sign` formula, and the key insight sat in section five. Rewritten to four sections, two diagrams and one formula it said the same thing and could actually be read. For scale: the two test explainers written under this rule came out at 2.4 KB and 2.9 KB of markdown; the same prompts without it produced 6.8 KB and 11.9 KB.

- **Core idea first**, never as a conclusion. If the payoff is in the last section, move it to the lead paragraph.
- **Four sections, give or take one** — the lead paragraph is not a section.
- **A diagram replaces prose, never accompanies it.** If a flowchart and a bullet list say the same thing, keep one; when a sequence diagram already names the actors, the actors diagram is the one to drop.
- **One formula, not its inverse.** Sign/Verify, encode/decode, ∧-intro/∧-elim — state one and say the other is its mirror.
- **Cut the periphery.** Optional fields, historical variants, edge cases, complexity tables: leave them out.

Explaining *why* a mechanism works is worth space; enumerating everything about it is not.

## 4. Structure

Lead paragraph, then four sections. For a protocol, algorithm or system:

1. 登場するもの — 図1つ、役割は1行ずつ（後の図で役者が出揃うなら省く）
2. 流れ — `sequenceDiagram` 1つ。登録と認証のような対の手順は1枚にまとめる
3. 何が効いているか — 式1本と、それを使う側の確認項目
4. なぜそう言えるか — 冒頭の1文を具体例で裏づける

For a math or logic concept:

1. 定義 — 式1本。記号の読みを1行で添える
2. 最小の例 — 具体的な項や値で1回だけ動かす
3. 規則・性質 — 変換規則や定理。分岐と失敗条件は `flowchart` 1枚にまとめると式の羅列より短い
4. なぜそうなるか — 一意性や停止性のような、定義から出る帰結を1つ

## 5. Heptabase mechanics

Write markdown to a scratch file, then create in one call — markdown avoids hand-building ProseMirror JSON:

```
heptabase note create --content-file <path>
```

| Element | Markdown |
|---|---|
| Diagram | fenced block, info string `mermaid:preview` (`params` is `[!]<language>[:displayMode]`; `preview` renders the figure instead of the code) |
| Display math | `$$ … $$` **on one line** |
| Inline math | `$ … $` inside a paragraph |
| Card / note link | `{{card <uuid>}}` |

Everything in that table imports faithfully, including `\\` row separators — this was tested. For anything outside it (tables, embeds, todo lists, video), read `references/card-content-schema.md` in the sub-skill.

**Two traps worth knowing before you write:**

- **The shell eats backslashes, the importer does not.** A quoted heredoc through the Bash tool turns `\\` into `\`, so a `\begin{aligned} … \\ … \end{aligned}` written that way loses its row break and renders as one line. Write files containing TeX with the **Write tool**, or `cat` the file back and confirm the backslashes survived. Heptabase itself preserves exactly what the file holds.
- **Mermaid labels with parens or commas break unquoted.** Write `A["認証器 (TPM・セキュリティキー)"]`, not `A[認証器 (TPM)]`.

**KaTeX, not LaTeX.** bussproofs (`\begin{prooftree}`) is not part of KaTeX, so a proof tree written that way may not render; the user's older `自然演繹（natural deduction）` note contains one. Use `array`, `aligned`, `cases`, and leave their old notes alone.

**Verify the import** — a mis-imported fence or formula shows up as literal text:

```
heptabase note read <cardId> > <scratch>/n.json
grep -oE '\\"type\\":\\"(code_block|math_display|math_inline|card)\\"' <scratch>/n.json | sort | uniq -c
grep -oE '\\"params\\":\\"[^\\]*\\"' <scratch>/n.json
grep -cE '[$]' <scratch>/n.json
```

Expect one `code_block` per diagram with `params` = `mermaid:preview`, one `math_display` per display formula, and no `$` left anywhere. Note the limits: node types are all the CLI can confirm. Whether the TeX and the Mermaid actually *render* is invisible until the user opens the card, and nothing validates this format — `lint-card.nu` is the concept-card checker and this note fails it by design, so do not run it.

**Point the card back at the note.** The note's mention only gives the card a backlink, which is easy to miss in Card Library. Append the pointer line to the concept card — not to the note — and confirm the card still passes its own lint:

```
printf '解説: {{card <noteId>}}\n' > <scratch>/kaisetsu.md
heptabase note append <conceptCardId> --content-file <scratch>/kaisetsu.md
nu ~/.claude/skills/creating-heptabase-concept-card/scripts/lint-card.nu <conceptCardId> --whiteboard <wbId>
```

`append` adds a real paragraph with a real mention and leaves the created-by-ai mark alone, so the card need not be recreated. The concept-card format allows this line (`解説:`) alongside `出典:` in either order. With no concept card there is nothing to append to — say so in the report.

If the note shows a diagram of the card's subject, append that one image to the card too, after the `解説:` line and with the same `src`, so the card read on its own shows what it names. The concept-card skill's Body item 5 has the rules: one image, no caption, stable hosts only.

**Rewriting** means `card trash <cardId>` plus a fresh `note create` from corrected markdown: `note save` takes ProseMirror JSON, and re-importing markdown is safer and faster. Report the trashed id.

**Environment on this machine:** `jq`, `python` and `node` are not usable, so parse CLI output with `grep` through the Bash tool (PowerShell's `ConvertFrom-Json` works if you need structure). Output shapes differ per command: `card list` → `{results:[…]}`, `tag list` → `{tags:[…]}`, `note create` → `{id,title}`.

## 6. Tags and whiteboard

Reuse the concept card's or the older note's, so the pair sits together. When there is nothing to reuse: look tags up with `heptabase tag list -n "<one bare word>"` (substring match, separators matched literally), attach them exactly as returned, and `heptabase tag create --name "<canonical name>"` when a fitting tag genuinely does not exist — a missing tag is a gap to fill, not a reason to under-tag. `tag create` cannot nest, so a new tag lands at the top level; mention the one-drag re-parenting in the report. Step 5 of `creating-heptabase-concept-card` has the full rule.

Place the note on the same whiteboard as the card (`whiteboard add-card`). Never create a whiteboard — that structure is the user's to invent.

## 7. Report

A few lines: the note id and title, its sections in one line each, tags and board, the `解説:` line you appended to the card (or why there was none), what you cut, and anything you could not confirm. The user asked for concision in the notes; the report follows the same rule.
