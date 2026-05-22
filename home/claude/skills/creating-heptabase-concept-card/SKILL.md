---
name: creating-heptabase-concept-card
description: 'Use when the user wants to save something they have learned (a term, food, concept, technology, person, etc.) into Heptabase using their established one-sentence concept-card format. Triggered by phrases like "Xのカードにして", "Xをまとめて", "覚えておきたい", "Xって何？保存して", or when they share a fact and clearly want it recorded as a new card. Skip for long-form notes, edits to existing cards, or non-save chat.'
---
## Overview

The user maintains a Japanese-language knowledge graph in Heptabase where each "concept card" captures one term, food, technology, or idea in a strict, compressed shape. This skill produces cards in exactly that shape and inlines references to related cards that already exist, so the graph stays connected.

**Reference exemplars:**
- Foreign-word notation, Latin-script origin: `バーニャ・カウダ(Bagna Cauda)` — id `2cdb488e-3c38-4922-a574-13aada502cc9`.
- Foreign-word notation, non-Latin origin (script + romanization): `バシレウス(βασιλεύς, Basileus)` — id `fc365328-6a45-4904-b1f4-25f74ea899c1`.
- Disambiguation / category tag (uses 【】, not parens): `独ソ電撃戦【ボードゲーム】` — id `4917f759-7dd3-4814-b788-ceafcbca278b`; `ヴォイテク【熊】` — id `4db6fe3b-af9f-44ee-bbdb-9b73c2e274f0`.

**REQUIRED SUB-SKILL:** This skill drives the Heptabase CLI. Use `heptabase:heptabase-cli` for the actual commands and their up-to-date flags.

## The format (strict)

**Title:** the bracketed annotation after the Japanese head name serves **one of two distinct purposes**, and each purpose uses a **different bracket type** so they are visually unambiguous.

| Purpose | Bracket | What goes inside |
|---|---|---|
| A — Foreign-word notation | `()` half-width parens | foreign script and/or romanization |
| B — Disambiguation / category tag | `【】` lenticular brackets | short Japanese categorical word |


Half-width `()` for A always, never full-width `（）`. Lenticular `【】` for B always.

### Purpose A — Foreign-word notation (the term is foreign-derived)

Used when the Japanese title is a transliteration, translation, or katakana rendering of a word from another language. The parenthetical shows the original.
- **Non-Latin original script** (Greek, Arabic, Cyrillic, Hebrew, Sanskrit/Devanagari, Chinese, …) where the Japanese is a **transliteration**: include BOTH the original script AND a Latin romanization, comma-separated, script first. Examples: `バシレウス(βασιλεύς, Basileus)`, `ハムサ(خمسة, Hamsa)`, `アムリタ(अमृत, amṛta)`. Preserve native diacritics (Greek polytonic accents, Arabic shadda, etc.). Omitting the original script loses the very information the user wants captured — romanization alone is not enough for transliterations.
- **Latin-script original** (Italian, English, French, German, Spanish, Latin, …): the original spelling alone is sufficient. Examples: `アンチョビ(anchovy)`, `バーニャ・カウダ(Bagna Cauda)`, `グレース・ホッパー(Grace Hopper)`, `alea jacta est`.
- **Translated work / concept** (Japanese title is a *translation* of a foreign work, not a transliteration): use the internationally-recognized form, usually English. Example: `千夜一夜物語(One Thousand and One Nights)`. Including the source-language original (here, Arabic) is optional and usually omitted unless the user emphasizes it.

When the original script is non-Latin and you don't know it offhand, look it up (Wikipedia, the source the user shared, etc.) — do not skip it just because the script is harder to type. If you genuinely cannot confirm the original script, romanization alone is acceptable, but flag this in the final report so the user can fill it in.

### Purpose B — Disambiguation / category tag (the term is ambiguous or needs a kind-marker)

Used when the bare Japanese head name would be ambiguous (a common word that could refer to multiple things) or when a short kind-tag adds clarity. **The annotation uses lenticular brackets `【】`, not parens** — this makes it instantly distinguishable from Purpose A at a glance.

Examples from the user's library:
- `独ソ電撃戦【ボードゲーム】` — distinguishes the board game from the historical event "独ソ電撃戦."
- `ヴォイテク【熊】` — distinguishes Wojtek the Polish military bear from any other Wojtek.

The category tag is typically one short Japanese noun: `【ボードゲーム】`, `【熊】`, `【映画】`, `【人物】`, etc.

### Distinguishing the two purposes

The bracket type itself signals which purpose:
- `(...)` half-width parens → Purpose A (foreign-word notation). Contents are foreign script and/or romanization.
- `【...】` lenticular brackets → Purpose B (disambiguation / category). Contents are a short Japanese categorical word.

If you find yourself putting Japanese category words inside `()`, or foreign script inside `【】`, you crossed the streams — re-pick the bracket.

### Purpose A + B combined (both reading and category needed)

When the same head name has BOTH a foreign-word reading worth preserving AND ambiguity that needs a category tag, append both bracket groups in order: `日本語名(reading)【category】`. The reading comes first (it identifies *what the term is*), the category second (it scopes *which entity*).

Examples (constructed — apply when the case arises):
- `アップル(Apple)【企業】` vs `アップル(Apple)【バンド】` — same name, distinguished by category.
- `アナクス(ἄναξ, Anax)` for the Greek title (no disambiguation needed if this is the primary entity); a same-named game would be `アナクス(Anax)【ゲーム】` (drop the Greek script — it's not authentic to the game).
- `プレステージ(The Prestige)【映画】` — only if there were a non-film プレステージ requiring disambiguation.

Rules for the combined form:
- Two separate bracket groups, A then B, no space between them: `日本語名(reading)【category】`.
- Each group follows its own rules: A uses `(原語script, romanization)` for non-Latin or `(original spelling)` for Latin; B uses `【短い日本語名詞】`.
- Skip the combined form unless **both** are genuinely informational. If the reading alone or the category alone uniquely identifies the card, use only that one.

### No parens
- Term already written natively in Japanese context (`Typescript`, `Clojure`, `proton`): use the term alone.
- Purely Japanese concept needing no disambiguation (`四元素`, `饕餮`, `逆茂木`): bare Japanese title.

**Body — exactly two blocks, in this order:**
1. An **H1 heading whose entire text is bold**, repeating the title verbatim.
1. **One** paragraph containing a **single Japanese sentence** that defines the concept. Mentions of related concepts that already have their own cards must be inline card references (ProseMirror `card` nodes), not plain text.

**Sentence template (dense, comma-separated, ends with `です。` or `こと。`):**


> `[材料・構成要素・前提となるもの]、[特徴・動作・役割]、[起源・由来・分類・カテゴリ]の[上位カテゴリ語]です。`


Concrete example (the exemplar card's body):


> にんにく、`<card:アンチョビ>`、オリーブオイルを煮立たせた熱いソースに、新鮮な野菜をディップして楽しむイタリア・ピエモンテ州発祥の伝統的な郷土料理です。


Where `<card:アンチョビ>` is a ProseMirror `card` inline node referencing the existing `アンチョビ(anchovy)` card — not the text string `アンチョビ`.

**Body itself excludes:** properties, sub-headings, bullet lists, code blocks, math, multiple paragraphs.

**Tags and whiteboard placement are part of the workflow** (steps 5 and 6 below) — the bare card is not "done" until the appropriate existing tag(s) are attached and the card is placed on the most fitting existing whiteboard. The exemplar Bagna Cauda card lacks these only because the user did not get around to it; the format intent is that every concept card finds its home in the tag/whiteboard structure.

## Workflow

### 1. Compose the title

Pick the Japanese head name. Then decide which parenthetical purpose (if any) applies — see the format spec for full rules:
1. **Foreign-derived term?** → Purpose A (foreign-word notation).
   - Non-Latin original (transliteration): `日本語名(原語script, romanization)`. Look up the script — do not skip it. Greek `βασιλεύς`, Arabic `خمسة`, Sanskrit `अमृत`, etc.
   - Latin-script original: `日本語名(original spelling)`.
   - Translation of a foreign work: `日本語名(international name)`.
1. **Ambiguous Japanese term that needs a kind-marker?** → Purpose B (disambiguation). Use lenticular brackets with a short Japanese categorical word: `【ボードゲーム】`, `【熊】`, `【映画】`, etc. Not parens.
1. **Both a foreign reading AND ambiguity with another entity?** → A + B combined: `日本語名(reading)【category】` — A's parens first, then B's lenticular brackets, no space between. Example: `アップル(Apple)【企業】`. Use sparingly — only when one alone wouldn't identify the card uniquely.
1. **Neither?** → bare Japanese, no brackets.

Sanity check: bracket type determines purpose. `()` = foreign-word reading (Purpose A). `【】` = Japanese category tag (Purpose B). If you used the wrong bracket type for the content, fix it before saving.

### 2. Compose the one sentence

Follow the template. Compress aggressively — one sentence is the style. Identify nouns inside the sentence that name concepts likely to be other cards (ingredients, parent categories, sibling concepts). Mark them as candidates for inline linking.

### 3. Find existing cards to inline-link

For each candidate noun, search:

```
heptabase card list -q "<concept name>" --limit 5
```

Only inline-link when the title match is unambiguous. If the search returns multiple plausible matches or none, leave the noun as plain text — do not invent a link, and do not create a stub card unless the user asks.

### 4. Create the card

**Case A — no inline card references needed (no related cards found):**

```
heptabase note create -c "# **<Title>**

<one Japanese sentence>"
```

The `**bold**` markdown around the heading text produces the required bold H1.

**Case B — at least one inline card reference is needed:**

`heptabase note create` accepts only markdown and cannot produce inline `card` nodes. Two-step pattern:
1. Create the card with the plain-text version of the sentence:
   
   ```
   heptabase note create -c "# **<Title>**
   
   <sentence with plain-text concept names>"
   ```
   
   Capture the returned `id`.
1. Replace the content with ProseMirror JSON that splices `card` nodes in place of those plain-text names:
   
   ```
   heptabase note save <newCardId> --content-file <pmJsonPath>
   ```

**ProseMirror skeleton** to splice (matches the exemplar exactly):

```
{
  "type": "doc",
  "content": [
    {
      "type": "heading",
      "attrs": {"level": 1},
      "content": [
        {"type": "text", "marks": [{"type": "strong"}], "text": "<TITLE>"}
      ]
    },
    {
      "type": "paragraph",
      "content": [
        {"type": "text", "text": "<前半テキスト>"},
        {"type": "card", "attrs": {"cardId": "<RELATED_CARD_ID>"}},
        {"type": "text", "text": "<中間テキスト>"},
        {"type": "card", "attrs": {"cardId": "<RELATED_CARD_ID_2>"}},
        {"type": "text", "text": "<後半テキスト>"}
      ]
    }
  ]
}
```

Notes:
- Split the paragraph's `content` array so each `card` node sits between the text fragments it replaced. Adjacent text fragments are fine; do not pre-merge them.
- The `card` node has no `content`, only `attrs.cardId`.
- Do not add `attrs.id` to heading/paragraph — the server fills those in.
- Write the JSON to a temp file and pass with `--content-file` when it contains complex Japanese / quotes, to avoid shell escaping issues.

### 5. Attach tag(s)

Decide which of the user's existing tags best describe the concept. **Creating a new tag is allowed when nothing fits** — but the real danger is silently producing duplicates that differ only in case or separator (the user already has `book`/`Book`, `term_rewriting`/`Term Rewriting` from past slip-ups). The procedure below exists to keep that from happening again.

Procedure:
1. List candidate tag keywords from the concept. For a food, that is typically `food` plus the cuisine (`italian`, etc.). For a programming language, the language name itself. For a math concept, `math` plus the sub-area (`set_theory`, `category_theory`, etc.). For a biological organism, `biology`. For a chemical / material concept, `chemistry`.
1. Verify each candidate exists with `heptabase tag list -n "<keyword>"`. The query is a case-insensitive substring match, so it will surface every case/separator variant.
1. If multiple variants exist (e.g., `Term Rewriting` vs `term_rewriting`), **always prefer the canonical form** (see "Tag naming convention" below — lowercase + snake_case). If the user has more members on the non-canonical side, you may consolidate (see "Tag reorganization" below) — otherwise just attach to the canonical one and leave the duplicate to deal with later.
1. Apply each confirmed tag:
   
   ```
   heptabase tag add --card-id <newCardId> --tag-name "<canonical name>"
   ```
1. **If no fitting tag exists, create one** in the canonical form before attaching:
   
   ```
   heptabase tag create --name "<canonical name>"
   heptabase tag add --card-id <newCardId> --tag-name "<canonical name>"
   ```
   
   Use `tag create` explicitly — do NOT just call `tag add` with a never-before-seen name. `tag add` silently mints the tag if it doesn't exist, which is exactly how the `book`/`Book` duplicates got there. Going through `tag create` forces you to confirm intent and naming convention. Prefer broad parent tags that will accumulate siblings (`biology`, `chemistry`, `physics`, `geography`) over hyper-specific one-offs.

### Tag naming convention (canonical form)
- Lowercase ASCII only.
- Multi-word: `snake_case` (`set_theory`, `term_rewriting`, `music_score`). Never Title Case, never hyphens, never spaces.
- Single-word: just the word (`food`, `italian`, `music`, `biology`).
- Programming language tags use the language's own preferred casing only when that is itself lowercase (`prolog`, `racket`, `apl`, `lisp`). When in doubt, lowercase.
- Snapshot of canonical roots: `food`, `italian`, `music`, `music_score`, `military`, `history`, `book`, `biology`, `chemistry`, `math`, `set_theory`, `category_theory`, `logic`, `combinator_logic`, `theory_of_computation`, `prolog`, `racket`, `apl`, `lisp`, `drum`, `myth`. Re-check `tag list` for current state.

### Tag reorganization (when invited)

The user has authorized reorganizing duplicate tags. The CLI exposes no rename/merge primitive, so consolidation is `tag add` (canonical) + `tag remove` (non-canonical) per card:
1. Find both variants: `heptabase tag list -n "<keyword>"`.
1. List the non-canonical's members: `heptabase tag cards <nonCanonicalId>`.
1. For each member: attach the canonical, then detach the non-canonical. Note the asymmetry — `tag add` takes `--tag-name`, but `tag remove` takes `--tag-id` (the UUID, not the name):
   
   ```
   heptabase tag add --card-id <cardId> --tag-name "<canonical>"
   heptabase tag remove --card-id <cardId> --tag-id <nonCanonicalTagId>
   ```
1. The empty non-canonical tag will remain (no delete primitive); that is fine — it just won't pick up new members.

Do this in the same turn only when the user has explicitly invited it, or when the non-canonical has at most 1–2 members and you are already touching it. Otherwise just attach to the canonical and report the duplicate so the user can decide.

Reference patterns observed in the user's library:

| Concept type | Typical tags |
|---|---|
| Food (general) | `food` |
| Italian food | `food`, `italian` |
| Programming language | language name as tag if it exists (`prolog`, `racket`, `apl`, `lisp`) |
| Math / logic | `math`, plus sub-area (`set_theory`, `category_theory`, `logic`, `combinator_logic`, `theory_of_computation`) |
| Music | `music`, plus instrument/sub-area (`drum`, `music_score`) |
| Book | `book` |
| Organism / biology | `biology` |
| Chemical / material | `chemistry` |
| Person, history, military, etc. | matching root tag if it exists (`history`, `military`, `myth`, ...) |


This table is a hint, not a closed list. Always re-check `tag list` for the current state.

### 6. Place on the most fitting whiteboard

The user organizes cards visually on topical whiteboards (there are ~48). New concept cards belong on the whiteboard that already collects the same kind of thing.

Procedure:
1. Decide on a candidate whiteboard name based on the concept (food → `Food(食)`; an Italian dish still goes on the same `Food(食)` board, not a cuisine-specific one — the user does not split food by cuisine on whiteboards). For a programming language, the same-named whiteboard (`Clojure`, `Racket`, `APL`, `Haskell`, ...). For math/logic, `Logic & Math` or a more specific board (`Category Theory`, `Type Theory`, `Term Rewriting`, ...).
1. Resolve the whiteboard id:
   
   ```
   heptabase whiteboard list -n "<keyword>"
   ```
   
   Confirm the name matches (whiteboard names often include Japanese + parenthesized English: `Food(食)`, `歴史(History)`, `知識(Knowledge)`).
1. If a single clear match exists, place the card:
   
   ```
   heptabase whiteboard add-card --whiteboard-id <whiteboardId> --card-id <newCardId>
   ```
1. If multiple plausible whiteboards exist (e.g., `Logic & Math` vs `Category Theory` for a category-theory concept — usually the more specific one wins), prefer the more specific one. Confirm with `heptabase whiteboard cards <whiteboardId>` if unsure that the existing inhabitants match the new card's flavor.
1. If no fitting whiteboard exists, **do not create one** — whiteboard creation is not supported by the CLI, and even if it were, this skill should not invent new top-level structure. Report to the user that the card was created without placement, and suggest where it might go.

Reference patterns observed in the user's library:

| Concept type | Whiteboard |
|---|---|
| Any food | `Food(食)` (id `9c9baad8-d6f0-4724-a7f9-c7ba8e8a3740`) |
| Programming language | a same-named whiteboard if one exists (`Clojure`, `Racket`, `APL`, `Haskell`, `Lean`, `Scheme`, `common lisp`, `Emacs Lisp`, `SQL`, `Uiua`) |
| Math / logic concept | most specific existing board: `Category Theory`, `Type Theory`, `Term Rewriting`, `Semantics`, `Logic Programming`, `Combinatory Logic`, `Constructive Mathematics`, otherwise `Logic & Math` |
| Music general | `Music`; theory → `music theory`; metal → `Metal`; score → `Score` |
| History / myth | `歴史(History)` / `神話(Myth)` |
| Game | `Game`, or franchise-specific board if one exists (`League of Legends`, `Arknights: Endfield`) |
| Misc factual things | `知識(Knowledge)` as fallback for general curiosity items |


This table is again a hint, not a closed list — re-check `whiteboard list` for the current state. Whiteboard IDs above may have shifted.

### 7. Report back

Print, in order:
1. The new card's `id` and `title`.
1. Each tag that was added (canonical name).
1. The whiteboard the card was placed on (name + id), or a note explaining why placement was skipped.
1. Each inline card reference that was inserted (related card title → its id).

Stop there. Do not chain into creating linked stub cards, setting tag database properties, or further organization unless the user asks.

## Quick reference

| Step | Command |
|---|---|
| Find related card | `heptabase card list -q "<name>" --limit 5` |
| Create card (no inline refs) | `heptabase note create -c "# **<Title>**\n\n<sentence>"` |
| Read current content + md5 | `heptabase note read <cardId>` |
| Replace content with ProseMirror | `heptabase note save <cardId> --content-file <path>` |
| Find existing tag (canonical name) | `heptabase tag list -n "<keyword>"` |
| Inspect a tag's members | `heptabase tag cards <tagId>` |
| Create new canonical tag | `heptabase tag create --name "<canonical name>"` |
| Attach tag | `heptabase tag add --card-id <cardId> --tag-name "<canonical name>"` |
| Detach tag (for consolidation) | `heptabase tag remove --card-id <cardId> --tag-id <tagId>` (note: id, not name) |
| Find whiteboard | `heptabase whiteboard list -n "<keyword>"` |
| Inspect a whiteboard's contents | `heptabase whiteboard cards <whiteboardId>` |
| Place card on whiteboard | `heptabase whiteboard add-card --whiteboard-id <wbId> --card-id <cardId>` |


## Common mistakes
- **Plain-text mention where a card exists.** If `アンチョビ` already has a card and you write the word `アンチョビ` as plain text, you broke the graph. Re-do step 3 and splice the `card` node.
- **Romanization-only title for a non-Latin original.** `バシレウス(Basileus)` without `βασιλεύς`, `ハムサ(Hamsa)` without `خمسة`, `アムリタ(amṛta)` without `अमृत` — all incomplete. The user wants the original script visible. Format is `日本語名(原語script, romanization)` with the script first.
- **Wrong bracket type for the purpose.** `()` half-width parens = Purpose A (foreign-word reading). `【】` lenticular brackets = Purpose B (Japanese category tag). Writing `独ソ電撃戦(ボードゲーム)` (parens around a Japanese category) or `バシレウス【βασιλεύς, Basileus】` (lenticular around a foreign reading) breaks the convention. Match bracket to purpose: `独ソ電撃戦【ボードゲーム】`, `バシレウス(βασιλεύς, Basileus)`.
- **Full-width parentheses** `（）` in the title. Always half-width `()`.
- **Multi-sentence body.** Compression is the style. Merge with commas.
- **Bullet lists, code blocks, math, sub-headings, extra paragraphs.** Not part of this format. Other note styles the user uses (definitions with LaTeX, book notes) are *different* formats — do not mix.
- **Unbolded H1.** The body H1 must be bold and identical to the title. Use `# **Title**` in markdown create.
- **Inventing related cards.** If `card list -q` does not return a clean match, leave the noun as plain text. Do not auto-create stubs.
- **Driving via ProseMirror from scratch instead of markdown-then-save.** When there are no inline refs, `note create` with markdown is enough — do not over-engineer.
- **Minting a tag via `tag add` instead of `tag create`.** `tag add` silently mints a tag if the name doesn't exist — which is fine in itself, except it bypasses the canonical-form check and is how duplicates like `book`/`Book` got created. When no existing tag fits, go through `heptabase tag create --name "<canonical>"` first, then `tag add`.
- **Creating a near-duplicate of an existing tag.** Before any tag operation, `tag list -n "<keyword>"` (case-insensitive substring) to see every variant. If `Term Rewriting` exists and you want `term_rewriting`, that's a reorganization opportunity, not "I'll just add the lowercase one too".
- **Skipping tags or whiteboard placement.** A bare card with no tag and no whiteboard is not finished — the exemplar's lack of them was an oversight, not the format. Always run steps 5 and 6.
- **Picking a too-broad whiteboard when a specific one exists.** If `Category Theory` exists, a category-theory concept goes there, not on the general `Logic & Math` board.
- **Setting tag database properties.** The skill does not touch property values; only tag attachment. Property editing is a separate task.

## Red flags — stop and re-check
- About to write the body in two sentences → merge to one.
- About to leave a known related concept as plain text → search and inline-link.
- About to call `tag add` with a tag name you have not verified with `tag list -n` → stop, look it up first.
- About to coin a new tag (e.g., `Italian`, `Food`) when a canonical version (`italian`, `food`) already exists → use the existing one.
- About to mint a tag through `tag add` instead of `tag create` → switch to `tag create` so the naming convention is an explicit decision, not a side effect.
- About to attach a tag in `TitleCase`, `Title Case`, or `kebab-case` → re-canonicalize to lowercase `snake_case`.
- Finishing without attaching any tag or placing on a whiteboard → revisit steps 5 and 6.
- Title uses `（）` → fix to `()`.
- Title for a non-Latin-origin term has only romanization, no original script → look up the original and prepend it: `バシレウス(βασιλεύς, Basileus)`, `ハムサ(خمسة, Hamsa)`.
- About to wrap a Japanese category tag in `()` instead of `【】` → switch brackets. `独ソ電撃戦(ボードゲーム)` is wrong; `独ソ電撃戦【ボードゲーム】` is right.
- About to wrap a foreign reading in `【】` instead of `()` → switch brackets. `バシレウス【βασιλεύς, Basileus】` is wrong; `バシレウス(βασιλεύς, Basileus)` is right.
- Combined case uses two `()` groups → second group should be `【】`. `アップル(Apple)(企業)` is wrong; `アップル(Apple)【企業】` is right.
- Heading is not bold → fix to `# **Title**`.
