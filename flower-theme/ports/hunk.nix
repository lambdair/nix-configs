# hunk's config, carrying a theme per variant of the selected flower. hunk
# accepts only hex colours, and its `auto` theme can pick a built-in theme
# only, so the theme is named.
{ config, lib, ... }:
let
  cfg = config.flowerTheme;
  flowerLib = import ../lib.nix { inherit lib; };

  theme =
    v:
    let
      r = v.hex.roles;
      mix = flowerLib.mix;
    in
    ''
      [themes.${v.name}]
      base = "${if v.mode == "dark" then "catppuccin-frappe" else "catppuccin-latte"}"
      label = "${v.title}"
      background = "${r.bg}"
      panel = "${r.crust}"
      panelAlt = "${r.statusline}"
      border = "${r.guide}"
      accent = "${r.keyword}"
      accentMuted = "${r.comment}"
      text = "${r.text}"
      muted = "${r.subtext}"
      addedBg = "${mix 0.22 r.bg r.added}"
      removedBg = "${mix 0.22 r.bg r.removed}"
      movedAddedBg = "${mix 0.14 r.bg r.added}"
      movedRemovedBg = "${mix 0.14 r.bg r.removed}"
      contextBg = "${r.bg}"
      addedContentBg = "${mix 0.38 r.bg r.added}"
      removedContentBg = "${mix 0.38 r.bg r.removed}"
      contextContentBg = "${r.bg}"
      addedSignColor = "${r.added}"
      removedSignColor = "${r.removed}"
      lineNumberBg = "${r.crust}"
      lineNumberFg = "${r.linenr}"
      selectedHunk = "${r.cursorline}"
      badgeAdded = "${r.added}"
      badgeRemoved = "${r.removed}"
      badgeNeutral = "${r.subtext}"
      fileNew = "${r.added}"
      fileDeleted = "${r.removed}"
      fileRenamed = "${r.info}"
      fileModified = "${r.changed}"
      fileUntracked = "${r.comment}"
      noteBorder = "${r.special}"
      noteBackground = "${r.statusline}"
      noteTitleBackground = "${r.selection}"
      noteTitleText = "${r.text}"

      [themes.${v.name}.syntax_scopes]
      "comment" = "${r.comment}"
      "keyword" = "${r.keyword}"
      "keyword.operator" = "${r.special}"
      "storage.type" = "${r.keyword}"
      "string" = "${r.string}"
      "constant" = "${r.constant}"
      "constant.numeric" = "${r.constant}"
      "entity.name.function" = "${r.function}"
      "support.function" = "${r.function}"
      "entity.name.type" = "${r.type}"
      "support.type" = "${r.type}"
      "variable" = "${r.text}"
      "variable.parameter" = "${r.subtext}"
      "punctuation" = "${r.subtext}"
    '';

  variants = map (flowerLib.variant cfg.flower) flowerLib.modes;
  selected = flowerLib.variant cfg.flower (flowerLib.resolve cfg.mode);
in
{
  config = lib.mkIf (cfg.flower != null) {
    xdg.configFile."hunk/config.toml".text = ''
      theme = "${selected.name}"

    ''
    + lib.concatMapStringsSep "\n" theme variants;
  };
}
