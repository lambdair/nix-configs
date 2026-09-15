# Where the colour anchors come from

The anchors in the spec (`docs/superpowers/specs/2026-09-11-flower-theme-design.md`)
were sampled on 2026-09-11 from official goods and key visuals. The images are
not committed. `images.csv` lists their URLs, and `regions.csv` lists every box
that was sampled. `annotate.nu` downloads the images, measures each box again
and draws the boxes onto copies:

```
nix shell nixpkgs#imagemagick nixpkgs#nushell -c nu flower-theme/sources/annotate.nu <out-dir>
```

It writes `<out-dir>/annotated/*.png` and `<out-dir>/measured.csv`, and prints
the boxes whose colour now differs from `recorded`. On 2026-09-15 all fifteen
URLs still served files byte-identical to the ones sampled.

## Method

A box is `w`×`h` pixels centred on (`x`, `y`). ImageMagick reduces it to
`colors` colours (`-colors 3` for square boxes, 5 or 6 for the three
hand-placed rectangles), and the box's colour is one of those clusters.

`recorded` is the cluster the 2026-09-11 run took. That run sorted the pixel
counts as strings, so it took the cluster whose count sorts last as text
("91" before "400"), not the largest one. In 55 of the 166 boxes, the
hand-placed rectangles included, `recorded` is not the largest cluster. `annotate.nu` sorts numerically, and `measured.csv` has every
cluster with its count, so both can be compared. The three hand-placed
rectangles (`ring`, `hem`, `ringcrop`) were read by eye from their clusters.

Each image also has a `backdrop` or `background` box. Clusters matching it
were treated as the photo's backdrop or white-balance cast, not the costume.
Eyes were sampled but not used: the boxes are 5–8 px and unreliable.

Images fetched and not sampled: `anemone-2`, `nemophila-5-tapestry`,
`nemophila-8-diorama`, `sunflower-2`, `sunflower-4-acsta-b`, `sunflower-5-live`,
`sunflower-7-tapestry`. Rejected after download: a diorama acrylic stand in a
different white costume, two live photos, and one image of the KADOKAWA figure
release.

## Anchors

"On target" is judged from the annotated image: whether the box lies on the
part it is named after. "Share" is the recorded cluster's share of the box.

### Anemone

| anchor | part | image, box | on target | recorded (share) | note |
|---|---|---|---|---|---|
| `#1A1A22` | coat black | anemone-1 `coat`, anemone-3-blouson `body` | yes | `#15131A` (100%), `#22222A` (91%) | between the two; no record of how it was chosen |
| `#C8202A` | red: shoes, strand | anemone-1 `shoe`, anemone-3-blouson `redtri`, anemone-6 `ringcrop` | yes | `#DB2022` (100%), `#B21D1E` (100%), `#B01F24` (10%) | between the three; the `ringcrop` red is the Anima logo behind the ring. The strand itself (anemone-6 `red` `#C84D4A`, `red2` `#9E3D3A`) was sampled but not used |
| `#DAD6D2` | hair highlight | anemone-6 `hair`, `hairR`, `hairL` | partly | `#D9D4CF` (75%), `#DAD9D7` (100%), `#E5E1DF` (94%) | `hairR` and `hairL` lie mostly on the background paper (`#E0DADC`), and `hair` straddles hair and background |
| `#A89A9E` | hair shade | anemone-1 `hairlow`, anemone-5 `hair` | partly | `#B5B0B5` (34%), `#977265` (67%) | `hairlow` is two-thirds backdrop; between the two values |
| `#7A7F8A` | silver ring, buckle | anemone-6 `ringcrop` | yes | `#7A7F8A` (15%) | cluster picked by eye from ring, hair and logo |
| `#645B66` | black hair flower | anemone-1, whole image | — | — | from an earlier whole-image histogram (`-resize 250x250 -colors 14`); the `flower` box gave `#C44C5C` |
| `#F5F8FD` | white sleeve band | anemone-3-blouson `band` | yes | `#F5F8FD` (59%) | |

### Nemophila

| anchor | part | image, box | on target | recorded (share) | note |
|---|---|---|---|---|---|
| `#1645A4` | royal blue | nemophila-2 `bodiceC` | partly | `#1645A4` (36%) | box straddles the bodice edge; the rest is the white sleeve |
| `#40BCF2` | sky blue | nemophila-6-anima3kv `bodiceC` | yes | `#40BCF2` (73%) | |
| `#33ACE3` | nemophila flower | nemophila-4-acsta `flower` | yes | `#33ACE3` (56%) | |
| `#D6DBEE` → `#FBFEFF` | skirt | nemophila-4-acsta `dresslow`, nemophila-6-anima3kv `skirt` | yes | `#D6DBEE` (100%), `#FBFEFF` (100%) | the first is a photo, close to its backdrop `#EAECF8` |
| `#C5B9B6` | hair | nemophila-9-anima2-jacket `hairblond` | yes | `#C5B9B6` (58%) | |
| `#A5A59E` | ring embroidery | nemophila-6-anima3kv `ring` | yes | `#A5A59E` (8%) | cluster picked by eye; the box is mostly white |
| `#3D3E4A` | boots | nemophila-4-acsta `boot` | yes | `#3D3E4A` (21%) | the largest cluster is `#4F505C` (79%) |
| `#333738` | black ribbon | nemophila-7-hoodtowel `ribbon` | yes | `#333738` (100%) | |

### Sunflower

| anchor | part | image, box | on target | recorded (share) | note |
|---|---|---|---|---|---|
| `#DBDB45` | dress yellow | sunflower-3-acsta `yellowD` | yes | `#DBDB45` (53%) | |
| `#BE9F25` | gold | sunflower-6-frameart `dress` | partly | `#BE9F25` (23%) | the largest cluster is the white coat, `#C1B9C1` (65%) |
| `#F1EA9C` | pale yellow | sunflower-1 `dressC` | yes | `#F1EA9C` (100%) | |
| `#5FD3D8` | sleeve lining aqua | sunflower-3-acsta `liningD`, `lining`, `liningC`; sunflower-8 `lining`; sunflower-6 `lining` | yes | `#C0F5FD`, `#C3EDF1`, `#95F7FA`, `#4F8D8E`, `#5597A9` | no box gave it; chosen between the lit and shaded values without a record |
| `#4B4A4E` | tights | sunflower-3-acsta `tights` | yes | `#4B4A4E` (100%) | |
| `#E8EAEB` / `#CCCDC1` | hair | sunflower-3-acsta `hair`, `hair2` | yes | `#E8EAEB` (94%), `#CCCDC1` (55%) | |
| `#71623D` | olive embroidery | sunflower-3-acsta `embroidery` | partly | `#71623D` (19%) | the largest cluster is `#D9D09F` (50%) |
| `#4A413A` | flower centre | sunflower-3-acsta `sunflower` | yes | `#4A413A` (42%) | |

The yellow strand in the hair was sampled once, from sunflower-9-genshiroku
`blondstrand` (`#D7C377`), and not used.
