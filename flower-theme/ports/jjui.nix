# jjui themes for the selected flower, plus the jj colours jjui reads back out
# of jj's own configuration, so `jj log` and jjui match.
{ config, lib, ... }:
let
  cfg = config.flowerTheme;
  flowerLib = import ../lib.nix { inherit lib; };

  theme =
    v:
    let
      r = v.hex.roles;
    in
    ''
      [colors]
      dimmed = "${r.comment}"
      title = { fg = "${r.keyword}", bold = true }
      shortcut = "${r.special}"
      matched = "${r.info}"
      target_marker = { fg = "${r.bg}", bg = "${r.error}", bold = true }
      source_marker = { fg = "${r.bg}", bg = "${r.info}" }
      success = "${r.added}"
      error = "${r.error}"
      ":selected" = { bg = "${r.cursorline}" }
      "flash:selected" = "${r.info}"
      "confirmation text" = { fg = "${r.keyword}", bold = true }
      "confirmation:selected" = { fg = "${r.text}", bg = "${r.selection}", bold = true }
      "confirmation dimmed" = "${r.subtext}"
      "help title" = { fg = "${r.function}", bold = true }
      "revisions details:selected" = { bg = "${r.cursorline}", bold = true }
      "revisions details dimmed:selected" = { fg = "${r.subtext}" }
      "revisions matched" = { underline = false, reverse = true }
      "oplog matched" = { underline = false, reverse = true }
      "revset title" = "${r.keyword}"
      "revset text" = { fg = "${r.string}", bold = true }
      "revset completion" = { bg = "${r.statusline}" }
      "revset completion dimmed" = { fg = "${r.comment}" }
      "revset completion text" = { fg = "${r.string}" }
      "revset completion matched" = { fg = "${r.warning}", underline = true, bold = true }
      "revset completion:selected" = { bg = "${r.cursorline}", bold = true }
      "revset completion dimmed:selected" = { fg = "${r.subtext}" }
      "revset completion text:selected" = { fg = "${r.string}" }
      "revset completion matched:selected" = { underline = true, bold = true }
      "status title" = { fg = "${r.bg}", bg = "${r.keyword}", bold = true }
      "git title" = { fg = "${r.bg}", bg = "${r.function}", bold = true }
      "bookmarks title" = { fg = "${r.bg}", bg = "${r.function}", bold = true }
      "git matched" = { fg = "${r.warning}", bold = true }
      "bookmarks matched" = { fg = "${r.warning}", bold = true }
      "git remote title" = { fg = "${r.keyword}", bold = true }
      "bookmarks remote title" = { fg = "${r.keyword}", bold = true }
      "git:selected" = { fg = "${r.info}", bold = true, underline = false }
      "bookmarks:selected" = { fg = "${r.info}", bold = true, underline = false }
      "picker dimmed" = { fg = "${r.comment}" }
      "picker matched" = { underline = true }
      "picker:selected" = { fg = "${r.info}", bg = "${r.cursorline}", bold = true, underline = false }
    '';

  variants = map (flowerLib.variant cfg.flower) flowerLib.modes;
  name = mode: "flower-${cfg.flower}-${if cfg.mode == "auto" then mode else cfg.mode}";
  selected = flowerLib.variant cfg.flower (flowerLib.resolve cfg.mode);
in
{
  config = lib.mkIf (cfg.flower != null) {
    xdg.configFile =
      lib.listToAttrs (
        map (v: lib.nameValuePair "jjui/themes/${v.name}.toml" { text = theme v; }) variants
      )
      // {
        "jjui/config.toml".text = lib.mkAfter ''

          [ui.theme]
          dark = "${name "dark"}"
          light = "${name "light"}"
        '';
      };

    # The keys jjui reads from jj; jj colours the rest of its own output.
    programs.jujutsu.settings.colors =
      let
        r = selected.hex.roles;
      in
      {
        "diff added" = r.added;
        "diff removed" = r.removed;
        "diff modified" = r.changed;
        "diff renamed" = r.info;
        "diff copied" = r.hint;
        change_id = r.keyword;
        commit_id = r.function;
        bookmark = r.type;
        conflict = r.error;
        error = r.error;
        warning = r.warning;
      };
  };
}
