# Helix themes for every flower variant; the selected flower follows the
# terminal's light/dark mode, with the dark variant where the terminal does
# not report one.
{ config, lib, ... }:
let
  cfg = config.flowerTheme;
  flowerLib = import ../lib.nix { inherit lib; };

  theme =
    v:
    let
      r = v.hex.roles;
      curl = color: {
        underline = {
          inherit color;
          style = "curl";
        };
      };
    in
    {
      "ui.background".bg = r.bg;
      "ui.text" = r.text;
      "ui.text.focus" = r.text;
      "ui.text.inactive" = r.comment;
      "ui.cursor" = {
        fg = r.bg;
        bg = r.subtext;
      };
      "ui.cursor.primary" = {
        fg = r.bg;
        bg = r.text;
      };
      "ui.cursor.match" = {
        bg = r.selection;
        modifiers = [ "bold" ];
      };
      "ui.cursorline.primary".bg = r.cursorline;
      "ui.selection".bg = r.selection;
      "ui.linenr" = r.linenr;
      "ui.linenr.selected" = r.subtext;
      "ui.statusline" = {
        fg = r.text;
        bg = r.statusline;
      };
      "ui.statusline.inactive" = {
        fg = r.comment;
        bg = r.crust;
      };
      "ui.statusline.normal" = {
        fg = r.bg;
        bg = r.function;
        modifiers = [ "bold" ];
      };
      "ui.statusline.insert" = {
        fg = r.bg;
        bg = r.string;
        modifiers = [ "bold" ];
      };
      "ui.statusline.select" = {
        fg = r.bg;
        bg = r.keyword;
        modifiers = [ "bold" ];
      };
      "ui.bufferline" = {
        fg = r.comment;
        bg = r.crust;
      };
      "ui.bufferline.active" = {
        fg = r.text;
        bg = r.statusline;
      };
      "ui.popup" = {
        fg = r.text;
        bg = r.crust;
      };
      "ui.help" = {
        fg = r.text;
        bg = r.crust;
      };
      "ui.menu" = {
        fg = r.text;
        bg = r.crust;
      };
      "ui.menu.selected" = {
        fg = r.text;
        bg = r.selection;
      };
      "ui.window" = r.guide;
      "ui.virtual.indent-guide" = r.guide;
      "ui.virtual.whitespace" = r.guide;
      "ui.virtual.ruler".bg = r.cursorline;
      "ui.virtual.inlay-hint" = r.comment;
      "ui.virtual.jump-label" = {
        fg = r.keyword;
        modifiers = [ "bold" ];
      };

      comment = {
        fg = r.comment;
        modifiers = [ "italic" ];
      };
      keyword = r.keyword;
      function = r.function;
      "function.macro" = r.special;
      type = r.type;
      constructor = r.type;
      namespace = r.type;
      string = r.string;
      "string.special" = r.special;
      constant = r.constant;
      "constant.character.escape" = r.special;
      attribute = r.special;
      label = r.special;
      tag = r.keyword;
      special = r.special;
      variable = r.text;
      "variable.builtin" = r.constant;
      operator = r.subtext;
      punctuation = r.subtext;

      "markup.heading" = {
        fg = r.keyword;
        modifiers = [ "bold" ];
      };
      "markup.bold".modifiers = [ "bold" ];
      "markup.italic".modifiers = [ "italic" ];
      "markup.strikethrough".modifiers = [ "crossed_out" ];
      "markup.link.url" = {
        fg = r.function;
        modifiers = [ "underlined" ];
      };
      "markup.link.text" = r.function;
      "markup.raw" = r.string;
      "markup.quote" = r.comment;
      "markup.list" = r.keyword;

      "diff.plus" = r.added;
      "diff.minus" = r.removed;
      "diff.delta" = r.changed;

      error = r.error;
      warning = r.warning;
      info = r.info;
      hint = r.hint;
      "diagnostic.error" = curl r.error;
      "diagnostic.warning" = curl r.warning;
      "diagnostic.info" = curl r.info;
      "diagnostic.hint" = curl r.hint;
    };

  name = mode: "flower-${cfg.flower}-${mode}";
in
{
  config = lib.mkIf (cfg.flower != null) {
    catppuccin.helix.enable = false;

    programs.helix = {
      themes = lib.listToAttrs (map (v: lib.nameValuePair v.name (theme v)) flowerLib.variants);
      settings = {
        theme = {
          dark = name "dark";
          light = name "light";
          fallback = name "dark";
        };
        editor.color-modes = true;
      };
    };
  };
}
