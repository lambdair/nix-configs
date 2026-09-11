# Ghostty themes for every flower variant; the selected flower follows the OS
# appearance. cmux reads the same configuration.
{ config, lib, ... }:
let
  cfg = config.flowerTheme;
  flowerLib = import ../lib.nix { inherit lib; };
  bare = lib.removePrefix "#";

  theme =
    v:
    let
      r = v.hex.roles;
      a = v.hex.ansi;
    in
    {
      palette = lib.imap0 (i: slot: "${toString i}=${a.${slot}}") flowerLib.ansiSlots;
      background = bare r.bg;
      foreground = bare r.text;
      cursor-color = bare r.text;
      cursor-text = bare r.bg;
      selection-background = bare r.selection;
      selection-foreground = bare r.text;
    };
in
{
  config = lib.mkIf (cfg.flower != null) {
    catppuccin.ghostty.enable = false;

    programs.ghostty = {
      themes = lib.listToAttrs (map (v: lib.nameValuePair v.name (theme v)) flowerLib.variants);
      settings.theme = "light:flower-${cfg.flower}-light,dark:flower-${cfg.flower}-dark";
    };
  };
}
