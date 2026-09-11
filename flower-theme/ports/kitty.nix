# kitty's automatic light/dark theme files for the selected flower. kitty
# rereads them only after a restart.
{ config, lib, ... }:
let
  cfg = config.flowerTheme;
  flowerLib = import ../lib.nix { inherit lib; };

  conf =
    mode:
    let
      v = flowerLib.variant cfg.flower mode;
      r = v.hex.roles;
      a = v.hex.ansi;
    in
    ''
      foreground ${r.text}
      background ${r.bg}
      selection_foreground ${r.text}
      selection_background ${r.selection}
      cursor ${r.text}
      cursor_text_color ${r.bg}
      url_color ${r.function}
      active_tab_foreground ${r.text}
      active_tab_background ${r.statusline}
      inactive_tab_foreground ${r.comment}
      inactive_tab_background ${r.crust}
      tab_bar_background ${r.crust}
    ''
    + lib.concatImapStrings (i: slot: "color${toString (i - 1)} ${a.${slot}}\n") flowerLib.ansiSlots;
in
{
  config = lib.mkIf (cfg.flower != null) {
    catppuccin.kitty.enable = false;

    xdg.configFile = {
      "kitty/dark-theme.auto.conf".text = conf "dark";
      "kitty/light-theme.auto.conf".text = conf "light";
      "kitty/no-preference-theme.auto.conf".text = conf "dark";
    };
  };
}
