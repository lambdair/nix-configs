# lazygit's colours for the selected flower.
{ config, lib, ... }:
let
  cfg = config.flowerTheme;
  flowerLib = import ../lib.nix { inherit lib; };
  v = flowerLib.variant cfg.flower (flowerLib.resolve cfg.mode);
  r = v.hex.roles;
in
{
  config = lib.mkIf (cfg.flower != null) {
    catppuccin.lazygit.enable = false;

    programs.lazygit.settings.gui.theme = {
      activeBorderColor = [
        r.keyword
        "bold"
      ];
      inactiveBorderColor = [ r.guide ];
      searchingActiveBorderColor = [
        r.warning
        "bold"
      ];
      optionsTextColor = [ r.function ];
      selectedLineBgColor = [ r.cursorline ];
      cherryPickedCommitBgColor = [ r.selection ];
      cherryPickedCommitFgColor = [ r.keyword ];
      unstagedChangesColor = [ r.removed ];
      defaultFgColor = [ r.text ];
    };
  };
}
