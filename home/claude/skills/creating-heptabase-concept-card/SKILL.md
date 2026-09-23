---
name: creating-heptabase-concept-card
description: 'Use when the user wants to save something they have learned (a term, food, concept, technology, person, etc.) into Heptabase using their established one-sentence concept-card format. Triggered by phrases like "Xのカードにして", "Xをまとめて", "覚えておきたい", "Xって何？保存して", or when they share a fact and clearly want it recorded as a new card. Skip for long-form notes, edits to existing cards, or non-save chat.'
---
## Overview

The user maintains a Japanese-language knowledge graph in Heptabase where each "concept card" captures one term, food, technology, or idea in a strict, compressed shape. This skill produces cards in exactly that shape and inlines references to related cards that already exist, so the graph stays connected.

**Reference exemplars:**
- Foreign-word notation, Latin-script origin, with an inline card mention: `バーニャ・カウダ(Bagna Cauda)` — id `2cdb488e-3c38-4922-a574-13aada502cc9`.
- Non-Latin origin (script + romanization), and the optional `出典:` line: `バシレウス(βασιλεύς, Basileus)` — id `fc365328-6a45-4904-b1f4-25f74ea899c1`.
- Disambiguation / category tag (uses 【】, not parens): `独ソ電撃戦【ボードゲーム】` — id `4917f759-7dd3-4814-b788-ceafcbca278b`; `ヴォイテク【熊】` — id `4db6fe3b-af9f-44ee-bbdb-9b73c2e274f0`.
- A concrete referent (a named product) carrying its official page as `出典:`: `レモスコ(LEMOSCO)` — id `aed01510-180f-4f29-9497-d50833e54f94`.

**REQUIRED SUB-SKILL:** This skill drives the Heptabase CLI. Use `heptabase:heptabase-cli` for the actual commands and their up-to-date flags.

## The format (strict)

### Title

A head name — usually Japanese — plus at most one bracket group of each kind. The bracket type *is* the signal of which purpose it serves:

| Purpose | Bracket | What goes inside |
|---|---|---|
| A — The other spelling of the head name | `()` half-width parens | foreign original, romanization, or kanji |
| B — Disambiguation / category tag | `【】` lenticular brackets | short Japanese categorical noun |

**Purpose A** — the parenthetical carries the head name's *other spelling*. Usually that means the head name is a Japanese rendering of a foreign term, whether a *transliteration* or a *translation*:
- **Non-Latin original, transliterated:** include BOTH the original script AND a Latin romanization, comma-separated, script first. Real cards in this shape: `バシレウス(βασιλεύς, Basileus)`, `ネフェレー(Νεφέλη, Nephele)`, `パレーシア(παρρησία, parrhesia)`, `アウトクラトール(αὐτοκράτωρ, Autokrator)`. Preserve native diacritics. Look the script up if you don't know it offhand — romanization alone loses the very information the user wants captured. If you genuinely cannot confirm it, romanization alone is acceptable but say so in the report.
  
  Older cards predate this rule and carry romanization only (`ハムサ(Hamsa)`, `サンスカーラ(Saṃskāra)`).
- **Latin-script original:** the original spelling alone. `アンチョビ(anchovy)`, `バーニャ・カウダ(Bagna Cauda)`, `ゲシュタルト崩壊(Gestaltzerfall)`.
- **Katakana rendering of a Chinese term:** the characters alone — a Japanese reader reads them directly, so romanization adds nothing. `サンプーチャン(三不粘)`. Unlike Greek or Sanskrit, this is a case where script-plus-romanization is *not* wanted. A Chinese-origin term the user writes straight in kanji takes no parens at all (`饕餮`).
- **Translated term, concept, or work:** the internationally recognized form, usually English. `他我問題(problem of other minds)`, `モノミス(monomyth)`, `ゴルディアスの結び目(Gordian Knot)`, `千夜一夜物語(One Thousand and One Nights)`. Including the source-language original is optional and usually omitted unless the user emphasizes it.

**Purpose A also covers kanji orthography.** When the head name is written in kana but has a kanji spelling worth preserving, the kanji goes in the same half-width parens: `かざぐるま(風車)`, `タガネ(鏨)`. The term is not foreign, but the parenthetical is doing the same job — carrying the other way of writing the head name. Use it when the kanji is the informative part, not for every word that happens to have one.

**Purpose B** — the bare head name would be ambiguous, or a short kind-marker adds clarity. This is rare; only a handful of cards use it. `独ソ電撃戦【ボードゲーム】` (the board game, not the historical event), `ヴォイテク【熊】`, `Inner Child【バンド】`. One short Japanese noun inside: `【ボードゲーム】`, `【熊】`, `【映画】`, `【企業】`. The head name is usually Japanese but need not be. Reach for B only when the bare name genuinely collides with something.

**Both** — when a foreign reading AND a category are *both* needed to identify the card: `頭名(reading)【category】`, A first, no space between the groups. No card in the library needs this yet, so the illustration is constructed: `アップル(Apple)【企業】` vs `アップル(Apple)【バンド】`. Use only when neither group alone would do.

**Neither** — bare head name, no brackets: `Typescript`, `Clojure`, `proton`, `四元素`, `饕餮`, `逆茂木`.

**Half-width `()`, with no space before it** — `アンチョビ(anchovy)`, never `（anchovy）` and never `アンチョビ (anchovy)`. This is not a cosmetic preference: the bracket style is how the title announces which of the user's note formats it belongs to. Full-width `（）` marks the LaTeX definition notes (`集合の存在公理（set existence）`, `自然演繹（natural deduction）` — over fifty of them), and a space before `(` marks the older bullet-list notes (`GPT (Generative Pre-trained Transformer)`, `ダイラタンシー (Dilatancy)` — over forty). Every one of those cards was checked: not a single concept card is among them. The nearest thing to an exception is one card, `ゴディバ夫人（レディ・ゴディバ）`, which opens with a proper concept sentence and then continues into a `補足情報：` section — the user extended it afterwards. It is the only such card in the library, and it is not a licence to write full-width parens or to append sections. Match the concept-card style exactly, and leave those other cards alone — noticing an inconsistency in them is report material, not an edit.

Never put a *category* word in `()` — a kanji spelling belongs there, a kind-marker does not — and never put a reading in `【】`.

### Body

1. An **H1 heading whose entire text is bold**, repeating the title verbatim. Every concept card has one — though a bold H1 alone does not make a card this format; plenty of the user's bullet-list notes have one too. What identifies the format is the bold H1 *plus* the single-paragraph body below.
1. **One** paragraph containing a **single Japanese sentence** that defines the concept. Concepts that already have their own cards appear as inline card mentions, not plain text.
1. *Conditional:* a pointer paragraph `解説: ` followed by one card mention, when a companion explainer note exists for the topic (`creating-heptabase-explainer-note` writes those). It is navigation, not exposition, so the one-sentence rule above is untouched — and it is the only thing that makes the explainer discoverable when the card is met in Card Library or through a mention, where the backlink panel is easy to miss. The explainer usually does not exist yet at create time; add the line afterwards with `heptabase note append <cardId> --content-file <path>` holding `解説: {{card <noteId>}}`, which appends a proper paragraph with a real mention and leaves the created-by-ai mark alone.
1. *Conditional:* a paragraph `出典: ` followed by one URL as a link. Include it in either of two cases:
   - **The card names a concrete referent** — something an entity owns and publishes a page about: a product, brand or company, product series, venue or facility, event, or named proprietary technology (`レモスコ(LEMOSCO)`, `プレック(Plek)`, `エバーチューン(EverTune)`, `レーヴ・デ・リュミエール(Rêve des Lumières)`). The user wants these cards to lead back to the thing itself, so link its **official page** (see step 2b). The discriminating question: *does someone own this and keep a page for it?* General concepts, techniques, dishes and food categories, natural features, historical or mythic subjects, and people get no link from this rule.
   - **The user shared a source.** Cite that URL. When both cases apply, the user's source wins; mention the official page in the report. This is an established habit, not a one-off — the Greek title-term batch (`バシレウス(βασιλεύς, Basileus)`, `アナクス(ἄναξ, Anax)`, `アルコーン(ἄρχων, Archon)`, `テュランノス(τύραννος, Tyrannos)`, `アウトクラトール(αὐτοκράτωρ, Autokrator)`) all carry it.

   Omit the line entirely when neither case applies.

   Both pointer paragraphs are optional and at most one of each is allowed. Either order passes the lint, because `note append` can only add at the end: a card that already carries `出典:` gains its `解説:` line below it.
1. *Conditional:* **one diagram**, so the card read on its own shows what the sentence describes. Only a diagram the explainer note behind the card's `解説:` line already shows qualifies — the note carries its attribution, so the card needs no caption and no citation of its own, and a card without an explainer gets no image. This also keeps photos-as-decoration off food and product cards. Append it after the `解説:` line with `heptabase note append <cardId> --content-file <path>` holding `![](<src>)`, copying the `src` from the note.
   - **At most one.** When the note has several for the subject (flat and rolling scissors), pick the one that shows the card's head name most directly; the rest stay in the note.
   - **Sharing is fine.** Sibling cards may carry the same diagram when one figure covers them all (lead, pure and lag pursuit on one plot); the title says which curve is meant.
   - **No fitting diagram → none.** Do not go looking for one just to fill the slot.
   - **Stable sources only.** Use a Wikimedia Commons original under `upload.wikimedia.org` rather than a `/thumb/` rendition. Images hotlinked from social media (`pbs.twimg.com`) break when the post goes, so they stay in the note.
   - `出典:` keeps its meaning (official page / the user's source); it never cites the diagram.

**Sentence template** — dense, comma-separated, ending in `です。`. Sweeping every concept card in the library: that ending is all but universal, none ends in `こと。` (so don't reach for it), and not one has a second `。`. The single-sentence rule is not an aspiration; it is how every card is written.

> `[材料・構成要素・前提となるもの]、[特徴・動作・役割]、[起源・由来・分類・カテゴリ]の[上位カテゴリ語]です。`

Concrete example — the exemplar Bagna Cauda card, where `{{card 093f9041-…}}` is an inline mention of the existing `アンチョビ(anchovy)` card, not the plain text `アンチョビ`:

> にんにく、`{{card 093f9041-cec5-4509-9371-24e83c1b525a}}`、オリーブオイルを煮立たせた熱いソースに、新鮮な野菜をディップして楽しむイタリア・ピエモンテ州発祥の伝統的な郷土料理です。

**The body excludes** properties, sub-headings, bullet lists, code blocks, math, captions, and any block beyond the two required ones, the optional `解説:` / `出典:` pointer lines and the one diagram. Other note styles in the user's library — LaTeX definitions, album cards built from bullet lists, book notes — are *different* formats; do not mix them in.

**Tags (step 5) and whiteboard placement (step 6) are part of the card,** not optional polish. A card with no tag and no board is unfinished.

## Workflow

### 1. Compose the title

Pick the Japanese head name, then:
1. **Does the head name have another spelling worth carrying?** → Purpose A, picking the case that applies: non-Latin transliteration `頭名(原語script, romanization)` (look the script up) · Latin-script origin `頭名(original spelling)` · Chinese term in katakana `頭名(漢字)`, no romanization · translated term or work `頭名(international name)` · kana with a telling kanji spelling `かざぐるま(風車)`.
1. **Ambiguous, or needs a kind-marker?** → Purpose B: `頭名【短い日本語名詞】`.
1. **Both needed?** → `頭名(reading)【category】`, A first, no space. Use sparingly.
1. **Neither?** → bare head name.

### 2. Compose the one sentence

Follow the template. Compress aggressively — one sentence is the style. Identify nouns inside it that name concepts likely to have their own cards (ingredients, parent categories, sibling concepts) and mark them as link candidates.

### 2b. Find the official page (concrete referents only)

If the card names a concrete referent (Body item 3), find its official page now with a web search and carry the URL to step 4. Prefer, in order: the owner's page for this exact item (product page, event page) → the owner's home page → a page the owner publishes elsewhere (e.g. a Rakuten store run by the maker). A shop, news, or wiki page is a fallback only when no official page exists — say so in the report. Keep the page you researched the facts from in mind too: when it *is* the official page, that is the one to cite.

### 3. Find existing cards to inline-link

For each candidate noun:

```
heptabase card list -q "<concept name>" --card-types note --limit 100
```

`--card-types note` keeps PDFs and highlights out of the results.

**`-q` is a fuzzy full-text filter, and results come back ordered by last edit time — not by relevance.** It matches body text (`ピエモンテ` finds `バーニャ・カウダ(Bagna Cauda)`) and it matches loosely (`ムリ` returns 70 unrelated cards), so a long result list is not evidence of anything. And the card you want is often *not* first: `-q "Typescript"` puts `bidirectional typechecking` above the actual `Typescript` card, because that one was edited more recently.

So: **scan every returned `title` for one whose head name is the concept you are naming.** Raise `--limit` (max 100) rather than trusting the top of a short list, and check `total` — if it exceeds your limit the real card may be past the cutoff, so narrow the query or paginate with `--offset`.

If no returned title is a clear match, leave the noun as plain text. Do not invent a card id, and do not create a stub card unless the user asks.

### 4. Create the card

Write the markdown to a scratch file — a temp directory, never inside the user's repository — and create in one call. Use `--content-file`: it avoids shell-escaping the Japanese, and a `\n` inside a quoted `-c` string is *not* expanded by PowerShell or bash.

```
heptabase note create --no-created-by-ai --content-file <path>
```

File contents:

```markdown
# **<Title>**

<one Japanese sentence, with {{card <uuid>}} in place of each linked concept name>

出典: [<URL>](<URL>)
```

- `**bold**` around the heading text produces the required bold H1; the card title is taken from the H1.
- `{{card <uuid>}}` becomes an inline `card` mention — no ProseMirror JSON needed. This is tested, including the awkward case where the mention sits directly between Japanese 読点 (`にんにく、{{card …}}、オリーブ`): it parses into `text, card, text` correctly. Use only ids resolved in step 3.
- Keep the `出典:` line only for a concrete referent's official page (step 2b) or a source the user shared (Body item 3); drop it otherwise. The URL doubles as the link text, matching the existing cards. The markdown link form is deliberate: it reproduces the link mark the バシレウス exemplar has, whereas a bare URL may or may not autolink.
- `--no-created-by-ai` keeps the card as the user's own knowledge entry: they supply the fact and you act as scribe. The mark is settable **only at create time** and cannot be changed by a later `append`/`save`, so it has to be on this call. See the sub-skill's `references/created-by-ai.md`.

If you get the create wrong in a way `save` cannot repair — the mark, or a mistyped title — `heptabase card trash <cardId>` soft-deletes it (`card restore <cardId>` undoes that) and you can create the card again. Say so in the report rather than leaving a broken card behind; do not trash anything you did not just create.

Whether the mentions parsed is checked by the lint in step 7 (`mention.unparsed`). The parse is known to work, so that finding should not appear — but if it does, repair the card with the fallback below.

**ProseMirror fallback** — only when the lint reports `mention.unparsed`. Run `heptabase note read <cardId>` for the current `content` and `contentMd5`. Do not author the document from scratch: take the `content` JSON the read handed you, and in the paragraph, split the text node at each literal `{{card <uuid>}}` and put a `card` node there instead. Read `references/card-content-schema.md` for the node shape, then:

```
heptabase note save <cardId> --content-md5 <md5> --content-file <path>
```

Always pass `--content-md5` so a concurrent edit is detected rather than clobbered.

### 5. Attach tag(s)

**Never attach a tag you have not just looked up.** `tag list -n` is a plain case-insensitive substring match — which means **search one bare word, never a full `snake_case` name.** Case variants always surface (`-n "MATH"` finds `mathematics`), but separators are matched literally: `-n "rewriting"` finds `term_rewriting`, while `-n "term_rewriting"` could never surface a `Term Rewriting` variant, because that string has no underscore. Searching the name you were about to create is exactly how a near-duplicate stays hidden.

1. Derive candidate keywords from the concept. A food → `food` plus the cuisine (`italian`, …). A programming language → the language name. A math concept → `mathematics` plus the sub-area (`set_theory`, `category_theory`, `logic`, …). Music → `music` plus instrument/sub-area (`guitar`, `drum`, `music_score`). An organism → `biology`. A chemical or material → `chemistry`. A book → `book`.
1. Look each one up:

   ```
   heptabase tag list -n "<keyword>"
   ```
1. **If it exists, attach it exactly as returned.** The name `tag list` gave you is known to resolve; a name you retyped is not. Do not "canonicalize" an existing one — the library legitimately holds `Zotero`, `English`, `cd_blu-ray`, `heptabase-tutorial`, and whether `tag add` would match `zotero` to `Zotero` or mint a second tag is not documented. Copy the string, don't improve it.

   ```
   heptabase tag add --card-id <newCardId> --tag-name "<name exactly as tag list returned it>"
   ```
1. **If nothing fits, create it** — a fitting tag that does not exist yet is a gap to fill, not a reason to under-tag. Use canonical form for a *new* tag — lowercase ASCII, `snake_case` when multi-word (`set_theory`, `music_score`):

   ```
   heptabase tag create --name "<canonical name>"
   heptabase tag add --card-id <newCardId> --tag-name "<canonical name>"
   ```

   Go through `tag create` rather than letting a bare `tag add` mint the tag: `tag add` creates an unknown name silently, while `tag create` **fails with 409 if the name already exists** — that 409 is the duplicate guard. Prefer a broad name that will accumulate siblings, the way `biology`, `chemistry`, and `physics` already do, over a hyper-specific one-off.

   **`tag create` takes only `--name`, so a new tag lands at the top level and the CLI cannot re-parent it.** `italian` sits under `food`, but a freshly created `turkish` starts beside `food` until the user drags it in the sidebar. Name it as though it were already nested (`turkish`, `security`, not `food_turkish`), attach it, and put the re-parenting in the report as a one-drag note. Leaving a card on a broad parent tag because the specific one could not be nested — `turkish` for a Turkish dish, `security` for FIDO2 — is exactly the failure this paragraph exists to prevent.

Do not work from a hard-coded list of tag names. The library holds over 80 tags and shifts over time, and guessing produces near-duplicates: the actual tags are `mathematics` and `combinatory_logic`, not `math` or `combinator_logic`. `tag list -n` is the only source of truth.

Several hits for one keyword is normal and usually means several *different* tags, not variants — `-n "MATH"` returns `mathematics`, `reverse_mathematics`, and `constructive_math`, all legitimate. Pick the one that fits and move on.

Genuine variants of the same tag (differing only in case or separator) are a different matter: attach to whichever has more members, since that is where the card's siblings are, and mention the duplicate in the report. Consolidating them — per card, `tag add` the surviving name, then `tag remove --card-id <id> --tag-id <otherTagId>`, over the members from `tag cards <tagId>`; note `remove` takes the id, not the name — is a separate task, done only when the user asks.

### 6. Place on the most fitting whiteboard

The user organizes cards visually on topical whiteboards (50 at last count). A new concept card belongs on the board that already collects the same kind of thing.

1. Pick a candidate board from the patterns and the principle below, then resolve its id:

   ```
   heptabase whiteboard list -n "<keyword>"
   ```

   Case-insensitive substring, so a fragment is enough and is safer than typing a full name: board names mix Japanese and English (`Food(食)`, `歴史(History)`, `圏論 (Category Theory)`), and `-n "Category"`, `-n "食"`, `-n "知識"` each find theirs.
1. Place the card:

   ```
   heptabase whiteboard add-card --whiteboard-id <whiteboardId> --card-id <newCardId>
   ```

   It is idempotent (a card already on the board is left alone) but it does not control *where* on the canvas the card lands — fine for concept cards. The sub-skill calls `add-card` a narrow legacy command and requires reading `references/whiteboard.md` before deliberate layout work; putting one new card on a board is the case `add-card` is still for. If the position actually matters, read that reference and use the canonical placement commands instead.
1. When several boards fit, prefer the more specific one (`圏論 (Category Theory)` over `Logic & Math`). `heptabase whiteboard cards <whiteboardId>` shows the current inhabitants if you are unsure the new card matches their flavor.
1. If nothing fits, **do not create a board.** `heptabase whiteboard create` does exist, so this is a rule, not a limitation — and the CLI has no way to delete a whiteboard again, so a board you invent is permanent. Inventing top-level structure is the user's decision. Report the card as unplaced and suggest where it might go.

Observed patterns — hints, not a closed list; re-check `whiteboard list`:

| Concept type | Whiteboard |
|---|---|
| Any food | `Food(食)` (id `9c9baad8-d6f0-4724-a7f9-c7ba8e8a3740`) — the user does not split food by cuisine |
| Programming language | the same-named board if one exists (`Clojure`, `Racket`, `APL`, `Haskell`, `Lean`, `Scheme`, `common lisp`, `Emacs Lisp`, `SQL`, `Uiua`) |
| Math / logic | most specific existing board — `圏論 (Category Theory)`, `Type Theory`, `Term Rewriting`, `Semantics`, `Logic Programming`, `Combinatory Logic`, `Constructive Mathematics` — otherwise `Logic & Math` |
| Music | `Music`; theory → `music theory`; metal → `Metal`; score → `Score` |
| Organism | `生物` (a small board — 周期ゼミ, マーモット(marmot), バタフライピー(butterfly pea) and the like) |
| History / myth | `歴史(History)` / `神話(Myth)` |
| Game | `Game`, or a franchise board if one exists (`League of Legends`, `Arknights: Endfield`) |
| Misc factual things | `知識(Knowledge)` — the general-curiosity fallback, and the largest board in the workspace |

The board follows *why the card is interesting*, not the taxonomy of its subject. `ヴォイテク【熊】` is a bear but sits on `歴史(History)`, because it is a war story; `生物` is for organisms recorded as organisms. When in doubt, `whiteboard cards <id>` and see which board's inhabitants the new card would look at home among.

### 7. Lint the card

Check the finished card mechanically:

```
nu ~/.claude/skills/creating-heptabase-concept-card/scripts/lint-card.nu <newCardId> --whiteboard <whiteboardId>
```

Drop `--whiteboard` if step 6 left the card unplaced. The script prints a JSON report and exits 1 on any error-severity finding. It checks the title's brackets, the body shape, the bold H1, the one-sentence definition, the `解説` and `出典` lines, the diagram (at most one, with a `src`, and only alongside `解説`), unparsed mentions, mentions of missing or trashed cards, that a tag is attached, and that the card is on the given board.

- **`ok: true`** — go on to the report.
- **An error** — fix the card and lint again. `mention.unparsed` → the ProseMirror fallback in step 4. `tags.none` or `whiteboard.not_placed` → steps 5 or 6. A title or body you got wrong → `card trash` and create again (step 4). Do not report success over an error.
- **A warning** (`sentence.ending`: a noun ending, with or without `。`) — older cards are written this way and the checker tolerates it, but a new card should end in `です。`. Rewrite the sentence unless the user asked for the noun ending, and mention it in the report either way.

What it cannot check is still yours: whether the sentence is a good definition, whether the original script is *correct* rather than merely present, whether a Latin-only reading needed a script at all (`ハムサ(Hamsa)` passes), and whether the tag and board were the right choices.

The checker itself lives in `scripts/hepta-lint/` (MoonBit, compiled to wasm on first run; `moon test --target wasm` there runs its tests against real-card fixtures).

### 8. Report back

Print, in order:
1. The new card's `id` and `title`.
1. Each tag attached (exact name).
1. The whiteboard the card landed on (name + id), or why placement was skipped.
1. Each inline card mention inserted (related card title → id).
1. The lint result: clean, or which warnings remain.
1. The `出典:` link and why it is there (official page / user's source), or that the card has none because it names a general concept.
1. The `解説:` pointer, if the card has one, and the note it points at.
1. Anything you could not confirm — an original script you had to omit, a duplicate tag you noticed and left alone.

Stop there. Do not chain into creating linked stub cards, setting tag database properties, or further organization unless the user asks.

One exception worth naming: when the card's subject is a mechanism — a protocol, an algorithm, a math or logic concept — the one sentence cannot explain how it works, and one diagram without math or prose cannot either. Do not stretch the card; `creating-heptabase-explainer-note` writes the companion note that carries the mechanism, and the card stays the index entry it is meant to be. Once that note exists, append the `解説:` line (Body item 3) so the pair points both ways, and then the note's diagram of the subject if it has one (Body item 5).

## Quick reference

| Step | Command |
|---|---|
| Find related card | `heptabase card list -q "<name>" --card-types note --limit 100` (edit-time order — scan all titles) |
| Create card | `heptabase note create --no-created-by-ai --content-file <path>` |
| Lint the finished card | `nu ~/.claude/skills/creating-heptabase-concept-card/scripts/lint-card.nu <cardId> --whiteboard <wbId>` |
| Read content + contentMd5 (fallback only) | `heptabase note read <cardId>` |
| Replace content (fallback only) | `heptabase note save <cardId> --content-md5 <md5> --content-file <path>` |
| Look up a tag | `heptabase tag list -n "<one bare word>"` (substring; separators matched literally) |
| Inspect a tag's members | `heptabase tag cards <tagId>` |
| Create a new tag | `heptabase tag create --name "<canonical name>"` (409 if it exists) |
| Attach tag | `heptabase tag add --card-id <cardId> --tag-name "<exact name>"` |
| Detach tag | `heptabase tag remove --card-id <cardId> --tag-id <tagId>` (id, not name) |
| Find whiteboard | `heptabase whiteboard list -n "<keyword>"` |
| Inspect a whiteboard | `heptabase whiteboard cards <whiteboardId>` |
| Place card on whiteboard | `heptabase whiteboard add-card --whiteboard-id <wbId> --card-id <cardId>` |

## Common mistakes
- **Plain-text mention where a card exists.** If `アンチョビ` has a card and you write the bare word, you broke the graph. Redo step 3 and use `{{card <uuid>}}`.
- **Romanization-only title for a non-Latin original.** Writing `バシレウス(Basileus)` where the card says `バシレウス(βασιλεύς, Basileus)`. Script first, then romanization. (Older cards that lack the script stay as they are — see Purpose A.)
- **Wrong bracket for the purpose.** `独ソ電撃戦(ボードゲーム)` and `バシレウス【βασιλεύς, Basileus】` both cross the streams. `()` = the head name's other spelling (foreign original, romanization, kanji), `【】` = a Japanese category word.
- **Retitling or rewriting an existing card.** This skill creates. Older cards break several of these rules — full-width parens, a space before `(`, a missing original script — because they predate them or belong to another format. They are neither models to copy nor yours to fix; an inconsistency you notice goes in the report, not into an edit.
- **Full-width `（）`, or a space before `(`.** Both belong to the user's *other* note formats. Concept cards use `頭名(reading)` tight and half-width.
- **Multi-sentence body, bullet lists, code blocks, math, sub-headings.** Compression is the style; merge with commas. The only permitted extra blocks are the `解説:` and `出典:` pointer lines and one diagram taken from the explainer note.
- **Unbolded H1.** `# **Title**`.
- **Forgetting `--no-created-by-ai`.** A later `append`/`save` will not clear the mark, and it is not a tag-database property that `card set-property` can reach. The reliable fix is `card trash` plus a fresh create. These cards are the user's own.
- **Attaching a tag without `tag list -n` first**, or rewriting an existing tag's casing instead of using it verbatim — both produce duplicates.
- **Minting a tag through `tag add`** instead of `tag create` when the name is new.
- **Reaching for ProseMirror JSON** when `{{card <uuid>}}` in markdown already does the job.
- **Inventing related cards or stub cards.** No clean match → plain text.
- **Skipping tags or whiteboard placement.** Steps 5 and 6 are part of the format.
- **Skipping a fitting tag because it does not exist yet**, or because `tag create` cannot nest it under its parent. Create it and note the re-parenting (step 5). Unlike whiteboards, new tags are yours to make.
- **No `出典:` on a card for a named product, brand, venue, event, or proprietary technology.** Find the official page (step 2b).
- **Linking a shop, news, or wiki page when an official page exists.** The official page comes first.
- **Adding an official link to a general concept.** Techniques, dishes, natural features, and people have no owner's page; leave the line off.
- **Picking a too-broad whiteboard** when a specific one exists.
- **Setting tag database properties.** Out of scope; attachment only.

## Red flags — stop and re-check
- Body is two sentences → merge to one.
- A known related concept sits in the sentence as plain text → search and link it.
- About to report success without a lint run that came back `ok: true` → run step 7.
- About to name a tag you have not seen in `tag list -n` output → look it up first, searching one bare word rather than the full name; if it genuinely does not exist, `tag create` it.
- About to leave a card on a broad parent tag because the specific one does not exist yet → `tag create` the specific one (step 5).
- About to lowercase an existing tag's name to "fix" it → attach it verbatim instead.
- `note create` without `--no-created-by-ai` → add it; this is irreversible.
- Title for a non-Latin-origin term carries only romanization → look up the script and prepend it.
- Title uses `（）`, a space before `(`, a category *word* in `()` (a kanji spelling there is fine), or a reading in `【】` → fix the brackets.
- Combined form written as `アップル(Apple)(企業)` → the second group is `【企業】`.
- Finishing with no tag or no whiteboard → steps 5 and 6.
- About to create a card for a named product, brand, venue, event, or proprietary technology with no `出典:` → step 2b.
- An explainer note for the topic exists but the card has no `解説:` line → append it (Body item 3); a pointer that only the backlink panel shows is a pointer the user will not find.
