# Flower themes phase 2: the everyday tools

Date: 2026-09-16

## Goal

Phase 1 gave Helix, kitty, Ghostty/cmux and WezTerm the flower palettes. The
tools used next to them — Claude Code, hunk, jjui and jj, the shell and the
smaller TUIs — still carry catppuccin frappe or their own defaults, so a
terminal now shows two palettes at once. Phase 2 ports them.

Neovim, Emacs, bat and btop are deliberately left out; see "Not in this phase".

## Constraints

Measured on 2026-09-16 from the installed versions and their sources:

- **Every tool in scope accepts hex colours.** hunk accepts *only*
  `#rrggbb`; jjui accepts hex, ANSI names and 256-colour indices.
- **Only jjui and zellij can hold a dark and a light theme at once** (jjui
  `[ui.theme] dark=/light=`, zellij `theme_dark`/`theme_light`). Claude Code,
  hunk, fzf, delta, nushell, starship, television, yazi and lazygit have one
  active theme.
- **hunk's `theme = "auto"` cannot pick a custom theme**: it probes the
  background with OSC 11 and falls back to `github-dark-default` or
  `github-light-default`, both hardcoded. A flower theme must be named.
- **catppuccin themes all of these today** except hunk, jjui and btop, so each
  port disables its app the way the phase 1 ports do. `catppuccin.yazi` writes
  `xdg.configFile."yazi/theme.toml"` directly, which collides with
  `programs.yazi.theme` at evaluation time unless disabled.
- **The palette has no diff *background* colours.** `added`, `removed` and
  `changed` are foregrounds at ≥4.5:1; Claude Code, hunk, delta and lazygit
  want backgrounds behind whole lines.
- `~/.config/hunk/config.toml` does not exist yet (only `state.json`), so
  home-manager can own the path without clobbering saved preferences. hunk
  writes view preferences back to it on quit; with the file owned by Nix that
  save fails, which the user accepted.
- **Claude Code skips symlinks in `~/.claude/themes/`**: a theme linked by
  `home.file` never appears in `/theme`, while the same JSON as a regular file
  does (checked on 2026-09-16). The directory must also exist when Claude Code
  starts, so the first activation needs a restart before `custom:flower-…`
  resolves.
- **Evaluating a home-manager specialisation costs about as much as the base
  configuration.** MacHome evaluated in about 12 s; with one specialisation
  about 19 s, and with six 44–55 s.
- Versions that fix a file format: zellij 0.45.1 (theme spec with
  `text_unselected`/`ribbon_selected`/… nodes, not the flat pre-0.41 palette),
  yazi 26.9.1 (`[mgr]`, not `[manager]`), jjui 0.10.9, jujutsu 0.45.1,
  hunk 0.22.0, Claude Code 2.1.270 (`custom:<slug>` themes).

## Design

### Resolving the mode

`flowerTheme.mode` stays the single switch. Ports that hold one theme use the
resolved mode, where `auto` means `dark` — the same choice Helix's `fallback`
already makes for terminals that cannot answer the light/dark query. jjui and
zellij, which hold both, get the pair when the mode is `auto` and the pinned
variant otherwise.

`lib.nix` grows two helpers so no port repeats the branch:

- `resolve = mode: if mode == "auto" then "dark" else mode`
- `pair = flower: mode: { dark = …; light = …; }` naming the two variants,
  collapsed to the pinned one when the mode is not `auto`

### Diff backgrounds

`lib.nix` gains `mix = ratio: a: b`, an sRGB blend using `lib.fromHexString`.
Diff line backgrounds are `mix 0.22 bg added` and `mix 0.22 bg removed`; the
word-level highlights use `mix 0.38`. Blending keeps the palettes and
`check.bb`'s role list untouched, and the backgrounds re-flow when the palettes
are retuned. The checker does not measure them; that is deferred with the rest
of the colour review.

### Ports

One module per app under `flower-theme/ports/`, each guarded by
`lib.mkIf (cfg.flower != null)` and each disabling its catppuccin app.

| port | writes | notes |
|---|---|---|
| claude | `home.activation` copies all six themes into `<configDir>/themes` as regular files; `programs.claude-code.settings.theme` names the selected one | `base` is `dark`/`light`; `overrides` carries text, status, diff, prompt and fullscreen tokens. Unknown tokens are ignored by Claude Code, so the map can be generous |
| hunk | `xdg.configFile."hunk/config.toml"` | `theme = "flower-<flower>-<mode>"` plus `[themes.<id>]` and `[themes.<id>.syntax_scopes]`; `base` is `catppuccin-frappe` or `catppuccin-latte` so unset keys stay close |
| jjui | `xdg.configFile."jjui/themes/<name>.toml"`, `[ui] theme` in the existing `jjui/config.toml`, and `programs.jujutsu.settings.colors` | jj's `colors` reach both jj's own output and jjui |
| nushell | `programs.nushell.extraConfig` | one `$env.config.color_config = { … }` assignment; the key list follows catppuccin's so nothing is left uncoloured |
| starship | extends the existing port | `[palettes.flower]` plus `palette`, and the flower indicator takes the strand colour |
| fzf | `programs.fzf.colors` | |
| television | `programs.television.themes.<name>` and `settings.ui.theme` | |
| delta | `programs.delta.options` | also drops catppuccin's `features = "catppuccin-frappe"`, which names a feature no included gitconfig defines |
| yazi | `programs.yazi.theme` | `[mgr]` keys |
| lazygit | `programs.lazygit.settings.gui.theme` | |
| zellij | `xdg.configFile."zellij/themes/<name>.kdl"` and `settings.theme_dark`/`theme_light` | written as text, since the theme spec nests colour triples |

### Switching

Changing `flowerTheme` and rebuilding takes a minute and edits a tracked file,
so switching goes through home-manager specialisations instead.

- `flowerTheme.specialisations`, set only in the Mac configuration so the
  Linux configurations do not pay the evaluation cost, builds every variant as
  `specialisation.flower-<flower>-<mode>` with `flower` and `mode` forced.
- `flower <flower> [mode]` runs that specialisation's activation script from
  the base generation. Activating a specialisation records a new generation
  without specialisations of its own, so the command takes the newest
  generation that has them rather than the current profile.
- The choice is saved in `$XDG_STATE_HOME/flower-theme/selection`;
  `flower reset` deletes it and activates the base generation, and
  `just home-mac` runs `flower --reapply` after its switch so a rebuild keeps
  the choice.
- cmux keeps its own theme state, so the command also runs
  `cmux themes set` (or `cmux themes clear` on reset). The other tools read
  their files when they start or reload, which the command lists.

### Not in this phase

- **bat** needs a Sublime `.tmTheme` (XML plist) generated from the palette.
- **btop** is in `home.packages` rather than `programs.btop`, so theming it
  means moving it first.
- **Neovim and Emacs** keep their own themes, as in phase 1.
- **zed** stays on catppuccin; it is a GUI editor, not part of the terminal.

## Verification

- Every revision: `just check` and `just fmt`; MacHome builds.
- After the build, `grep -RlE 'frappe|Frappe|catppuccin' <generation>/home-files`
  lists only the deferred tools (bat, yazi's tmTheme, zed). Anything else is a
  port that did not take over.
- Claude Code: `~/.claude/themes/` holds six regular files and `settings.json`
  names the selected one; the theme is listed in `/theme`.
- Switching: `flower sunflower light` changes Claude Code's theme, Ghostty's
  `theme` and hunk's `theme` together, and a second `flower anemone dark`
  still finds the base generation.
- `just home-mac` changes every daily tool at once, so it runs only with the
  user's go-ahead.

## Revisions

1. This spec.
2. `lib.nix`: mode resolution and the blend helper.
3. jjui and jj.
4. hunk.
5. Claude Code.
6. nushell.
7. starship palette.
8. fzf.
9. television.
10. delta.
11. yazi.
12. lazygit.
13. zellij.
14. Specialisations for every variant.
15. The `flower` command.
