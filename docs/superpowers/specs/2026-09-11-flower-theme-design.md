# Flower themes: Anemone, Nemophila and Sunflower

Date: 2026-09-11

## Goal

Replace catppuccin frappe with three custom colour themes inspired by the
costumes of the virtual singer ヰ世界情緒: 普遍体 Anemone, Nemophila and
Sunflower. Each flower gets a dark and a light variant, six in total, so that
the flower (mood) and the polarity (ambient light) can be chosen independently.

The work is split in two phases. This spec covers phase 1: the palettes, an
overview page, Helix and the three terminals (kitty, Ghostty/cmux, WezTerm).
Phase 2 (Neovim, Emacs, bat, delta, fzf, television, …) gets its own spec once
the palettes have been judged in daily use.

## Constraints

Measured on 2026-09-11 by capturing Helix's screen from kitty
(`kitty @ get-text --ansi`) and computing WCAG contrast and OKLab ΔE:

| theme | syntax colours | min contrast | closest pair ΔE |
|---|---|---|---|
| catppuccin_frappe | 13 | 4.53 | 0.052 |
| catppuccin_latte | 13 | 2.31 | 0.051 |
| github_dark | 8 | 4.12 | 0.063 |
| github_light | 8 | 4.55 | 0.080 |

On a light background no sampled theme keeps both many hues and 4.5:1:
latte keeps its hues and drops its yellow to 2.31:1, github_light keeps
contrast and caps the hue count. The palettes must make that trade-off
explicitly per variant rather than inherit it from a template.

Terminal behaviour, verified in the kitty 0.48.2, Ghostty 1.3.2 (bundled in
cmux 0.64.10) and helix-steel sources:

- kitty and cmux answer the mode-2031 light/dark query from the luminance of
  their own background, not from the OS appearance. WezTerm does not implement
  it, so Helix falls back to its `fallback` theme there.
- cmux accepts an OSC 11 background change and reports the new colour back,
  but keeps drawing the configured background, which it paints from its host
  layer (checked in a cmux tab on 2026-09-11).

## Colour anchors

Sampled region by region from official goods (acrylic stands, key visuals,
Blu-ray jacket, plush photos from FINDME STORE and KADOKAWA). Photos carry
white-balance casts, so backdrops and props are excluded. Hair is a shared
champagne silver across all three; the identity of each costume is the tuft of
colour inside the hair — red, blue, yellow — called the *strand* below.

**Anemone** — coat black `#1A1A22`, strand red `#C8202A`, hair highlight
`#DAD6D2`, hair shade `#A89A9E`, silver ring `#7A7F8A`, black hair-flower
grey-violet `#645B66`, sleeve band white `#F5F8FD`.

**Nemophila** — royal blue `#1645A4`, sky blue `#40BCF2`, nemophila flower
`#33ACE3`, skirt `#D6DBEE`→`#FBFEFF`, hair `#C5B9B6`, ring embroidery
`#A5A59E`, boots `#3D3E4A`, ribbon black `#333738`.

**Sunflower** — dress yellow `#DBDB45` (greenish) to gold `#BE9F25`, pale
yellow `#F1EA9C`, sleeve-lining aqua `#5FD3D8`, tights `#4B4A4E`, hair
`#E8EAEB`/`#CCCDC1`, embroidery olive `#71623D`, flower centre `#4A413A`.

The anchors seed hue families rather than fix hex values: final colours are
hand-tuned per variant, may move freely in lightness and chroma to pass the
checker below, and roles the costume cannot fill (most ANSI colours, several
Nemophila syntax roles) are derived. Measured against the anchors, several
cannot be used as they are:

- Anemone red `#C8202A` is 3.04:1 on `#1A1A22`, so dark needs a lighter red.
- Nemophila sky `#40BCF2` and flower `#33ACE3` are ΔE 0.05 apart, so only one
  can be a syntax colour; royal blue `#1645A4` is 1.99:1 on a dark background
  and belongs to surfaces there.
- The two whites `#F5F8FD` and `#FBFEFF` are ΔE 0.02 apart, too close to serve
  as distinct light surfaces.
- Sunflower's yellows are 1.39–2.41:1 on white; a light ANSI yellow needs
  something like `#9C8400`.

No reference image is committed.

## Design

### Layout

```
flower-theme/
├── palettes/{anemone,nemophila,sunflower}.toml
├── lib.nix        load the TOML, resolve roles to hex
├── variants.nix   every variant as JSON, the checker's input
├── check.bb       palette checker; also emits the measurements as JSON
├── check_test.bb  checker tests
├── check.nix      the flake check
├── page.bb        overview page renderer
├── page.nix       the overview page package
├── module.nix     home-manager module
└── ports/         one generator per app: helix, ghostty, kitty, wezterm, starship
```

The directory is self-contained and the palettes are TOML rather than Nix, so
it can later move to its own repository with its history if it is published.

### Palette format

Each flower file holds two layers per variant: named colours carrying the
costume part they come from, and a role table that refers to those names. The
overview page shows the names; the ports read the roles.

```toml
name = "Anemone"
strand = "#C8202A"   # the strand anchor; the checker compares hues with it

[dark.colors]
coat = { hex = "#1A1A22", label = "コートの黒" }
red  = { hex = "#C8202A", label = "靴・髪房の赤" }

[dark.roles]
bg = "coat"
keyword = "red"

[dark.ansi]
red = "red"

[light.colors]
# same shape
```

Roles:

| group | roles |
|---|---|
| surfaces | crust, bg, cursorline, selection, statusline |
| text | text, subtext, comment, line number, indent guide |
| syntax | keyword, function, type, string, constant, special |
| diagnostics | error, warning, info, hint |
| diff | added, removed, changed |
| terminal | the 16 ANSI colours |

### Checker rules

`check.bb` fails when a variant breaks any of:

- text ≥ 7:1 against bg; syntax, diagnostics and diff ≥ 4.5:1; comment
  ≥ 3:1; line number ≥ 2.5:1
- bg, cursorline and selection pairwise ΔE ≥ 0.03 in OKLab
- closest pair of syntax colours ΔE ≥ 0.06
- the chromatic ANSI colours (red, green, yellow, blue, magenta, cyan and
  their bright forms) ≥ 3:1 and within ±30° of their canonical OKLCH hue, so
  error red and diff red/green keep their meaning; black and white are
  exempt, since ANSI black sits close to the background by design
- every variant uses a colour within ±10° of the strand anchor's OKLCH hue,
  as a syntax foreground or, where it cannot reach the contrast (Sunflower's
  yellow on light), as selection or statusline

bb cannot parse TOML, so `lib.nix` loads the palettes with `builtins.fromTOML`
and hands the checker the resolved variants as JSON. The checker runs as a
new `checks.<system>.flower-theme` flake output, so `just check` covers it.

### Options

- `flowerTheme.flower` — `null`, `"anemone"`, `"nemophila"` or `"sunflower"`.
  `null` leaves catppuccin untouched.

Theme names are `flower-<flower>-{dark,light}` in every app. Helix, Ghostty
and WezTerm get all six variants when a flower is selected, so any of them can
be tried by hand; kitty gets only the selected flower's pair.

### Ports

Selecting a flower sets `catppuccin.<app>.enable = false` for the app being
themed; catppuccin assigns `settings.theme` without `mkDefault`, so the two
cannot coexist.

- **Helix** — the six themes go into `programs.helix.themes`, and
  `theme = { dark, light, fallback }` with `fallback` set to the dark variant,
  which is what WezTerm gets. `editor.color-modes = true` moves from
  catppuccin to the module.
- **Ghostty / cmux** — `programs.ghostty.themes` plus
  `theme = "light:…,dark:…"`, the same form catppuccin already writes and cmux
  already reads.
- **kitty** — `dark-theme.auto.conf` and `light-theme.auto.conf` written with
  `xdg.configFile`; home-manager's `autoThemeFiles` only accepts themes shipped
  in kitty-themes. kitty rereads them only after a restart.
- **WezTerm** — `programs.wezterm.colorSchemes`, and a generated Lua module
  naming the flower; `wezterm.lua` picks the scheme from
  `wezterm.gui.get_appearance()` and falls back to Catppuccin Frappe when the
  module is absent.

### Random flower per session (not implemented)

A random flower per cmux session would recolour the terminal with OSC
sequences. cmux applies the palette and foreground but keeps drawing its
configured background, so a session would pair one variant's text colours
with another variant's background, a combination the checker never saw.
Changing the flower is done by editing `flowerTheme.flower`.

### Prompt indicator

The starship prompt shows the configured flower and the current polarity, for
example `🌻 sunflower·light` (🌺 anemone, 💠 nemophila, 🌻 sunflower).

- A starship `custom` module prints the flower's symbol and name, which Nix
  bakes in, and appends `·dark` or `·light` from
  `defaults read -g AppleInterfaceStyle`, run on every prompt so it follows
  an appearance change.
- starship runs the command itself, so the indicator works the same in
  nushell (cmux) and in the zsh of kitty and WezTerm.
- Where `defaults` does not exist (Linux, WSL) the polarity is omitted and
  only the flower is shown.

### Overview page

`packages.<system>.flower-palette`, added beside `ci-heavy`, builds
`index.html` with babashka's built-in hiccup: for each variant the named
swatches with their costume labels and hex, the role table, contrast against
bg with the checker's verdict, and a highlighted code sample. The numbers come
from the JSON `check.bb` emits, so contrast is computed in one place.

## Verification

- Every revision: `just check` and `just fmt`; MacHome builds; NixHome and
  WSLHome evaluate, since the module is imported from the shared
  `home/default.nix`.
- Palettes: judged by the user on the overview page and in Helix running in
  kitty with a sample file.
- Prompt indicator: the prompt shows the flower and switches between `·dark`
  and `·light` with the OS appearance.
- `just home-mac` changes the daily terminal, so it runs only with the user's
  go-ahead.

## Revisions

0. Throwaway probe, not committed: whether cmux's `light:…,dark:…` theme
   actually switches on an appearance change (it does), and whether cmux shows
   OSC colour changes (it does not, which ruled out a random flower).
1. `lib.nix`, `check.bb` and the `checks` flake output.
2. `anemone.toml`.
3. `nemophila.toml`.
4. `sunflower.toml`.
5. Overview page.
6. Module options and the Helix port (fixed mode).
7. Ghostty port.
8. kitty port.
9. WezTerm port.
10. Prompt indicator: the starship module.
