# Colour themes after the costumes of ヰ世界情緒 (Anemone, Nemophila,
# Sunflower), each in dark and light.
{ lib, ... }:
let
  flowerLib = import ./lib.nix { inherit lib; };
in
{
  imports = [ ./ports/helix.nix ];

  options.flowerTheme = {
    flower = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum flowerLib.flowers);
      default = null;
      description = "Flower to theme the apps with; null keeps catppuccin.";
    };
    mode = lib.mkOption {
      type = lib.types.enum [
        "auto"
        "dark"
        "light"
      ];
      default = "auto";
      description = "Variant shown: auto follows the appearance, dark or light pins it.";
    };
  };
}
