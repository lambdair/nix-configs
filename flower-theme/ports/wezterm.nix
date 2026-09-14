# WezTerm colour schemes for every flower variant, and a Lua module naming the
# selected flower's pair for wezterm.lua.
{ config, lib, ... }:
let
  cfg = config.flowerTheme;
  flowerLib = import ../lib.nix { inherit lib; };
  name = mode: "flower-${cfg.flower}-${if cfg.mode == "auto" then mode else cfg.mode}";

  scheme =
    v:
    let
      r = v.hex.roles;
      colours = map (slot: v.hex.ansi.${slot}) flowerLib.ansiSlots;
    in
    {
      ansi = lib.take 8 colours;
      brights = lib.drop 8 colours;
      background = r.bg;
      foreground = r.text;
      cursor_bg = r.text;
      cursor_fg = r.bg;
      cursor_border = r.text;
      selection_bg = r.selection;
      selection_fg = r.text;
    };
in
{
  config = lib.mkIf (cfg.flower != null) {
    catppuccin.wezterm.enable = false;

    programs.wezterm.colorSchemes = lib.listToAttrs (
      map (v: lib.nameValuePair v.name (scheme v)) flowerLib.variants
    );

    xdg.configFile."wezterm/flower.lua".text = ''
      return { dark = "${name "dark"}", light = "${name "light"}" }
    '';
  };
}
