# zellij themes for the selected flower, written as KDL because the theme spec
# nests a colour triple per UI component.
{ config, lib, ... }:
let
  cfg = config.flowerTheme;
  flowerLib = import ../lib.nix { inherit lib; };

  rgb =
    hex:
    lib.concatMapStringsSep " " (i: toString (lib.fromHexString (builtins.substring (1 + 2 * i) 2 hex)))
      [
        0
        1
        2
      ];

  theme =
    v:
    let
      r = v.hex.roles;
      a = v.hex.ansi;

      component = name: base: background: [
        "        ${name} {"
        "            base ${rgb base}"
        "            background ${rgb background}"
        "            emphasis_0 ${rgb r.keyword}"
        "            emphasis_1 ${rgb r.function}"
        "            emphasis_2 ${rgb r.type}"
        "            emphasis_3 ${rgb r.string}"
        "        }"
      ];

      players = lib.imap1 (i: colour: "            player_${toString i} ${rgb colour}") [
        a.red
        a.green
        a.yellow
        a.blue
        a.magenta
        a.cyan
        a.bright-red
        a.bright-green
        a.bright-yellow
        a.bright-blue
      ];
    in
    lib.concatStringsSep "\n" (
      [
        "themes {"
        "    ${v.name} {"
      ]
      ++ component "text_unselected" r.text r.bg
      ++ component "text_selected" r.text r.cursorline
      ++ component "ribbon_unselected" r.text r.statusline
      ++ component "ribbon_selected" r.bg r.keyword
      ++ component "table_title" r.keyword r.bg
      ++ component "table_cell_unselected" r.text r.bg
      ++ component "table_cell_selected" r.text r.cursorline
      ++ component "list_unselected" r.text r.bg
      ++ component "list_selected" r.text r.cursorline
      ++ component "frame_unselected" r.guide r.bg
      ++ component "frame_selected" r.keyword r.bg
      ++ component "frame_highlight" r.warning r.bg
      ++ component "exit_code_success" r.added r.bg
      ++ component "exit_code_error" r.error r.bg
      ++ [ "        multiplayer_user_colors {" ]
      ++ players
      ++ [
        "        }"
        "    }"
        "}"
        ""
      ]
    );

  variants = map (flowerLib.variant cfg.flower) flowerLib.modes;
  name = mode: "flower-${cfg.flower}-${if cfg.mode == "auto" then mode else cfg.mode}";
in
{
  config = lib.mkIf (cfg.flower != null) {
    catppuccin.zellij.enable = false;

    xdg.configFile = lib.listToAttrs (
      map (v: lib.nameValuePair "zellij/themes/${v.name}.kdl" { text = theme v; }) variants
    );

    programs.zellij.settings = {
      theme_dark = name "dark";
      theme_light = name "light";
    };
  };
}
