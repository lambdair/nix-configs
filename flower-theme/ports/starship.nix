# A starship prompt segment with the selected flower and the variant shown,
# such as "🌻 sunflower·light". In auto mode the variant comes from the current
# macOS appearance, and without `defaults` (Linux) only the flower is shown.
{ config, lib, ... }:
let
  cfg = config.flowerTheme;

  symbols = {
    anemone = "🌺";
    nemophila = "💠";
    sunflower = "🌻";
  };
in
{
  config = lib.mkIf (cfg.flower != null) {
    programs.starship.settings.custom.flower = {
      description = "Flower theme and the variant shown";
      when = true;
      shell = [ "sh" ];
      command =
        if cfg.mode == "auto" then
          "if defaults read -g AppleInterfaceStyle 2>/dev/null | grep -q Dark; then echo dark; elif command -v defaults >/dev/null; then echo light; fi"
        else
          "echo ${cfg.mode}";
      format = "[${symbols.${cfg.flower}} ${cfg.flower}(·$output)]($style) ";
      style = "bold";
    };
  };
}
