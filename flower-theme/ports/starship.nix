# A starship prompt segment with the selected flower and the current macOS
# appearance, such as "🌻 sunflower·light". Without `defaults` (Linux) only the
# flower is shown.
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
      description = "Flower theme and the current macOS appearance";
      when = true;
      shell = [ "sh" ];
      command = "if defaults read -g AppleInterfaceStyle 2>/dev/null | grep -q Dark; then echo dark; elif command -v defaults >/dev/null; then echo light; fi";
      format = "[${symbols.${cfg.flower}} ${cfg.flower}(·$output)]($style) ";
      style = "bold";
    };
  };
}
