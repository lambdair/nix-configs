# Colour themes after the costumes of ヰ世界情緒 (Anemone, Nemophila,
# Sunflower), each in dark and light.
{ lib, ... }:
let
  flowerLib = import ./lib.nix { inherit lib; };
in
{
  imports = [
    ./ports/helix.nix
    ./ports/ghostty.nix
    ./ports/kitty.nix
    ./ports/wezterm.nix
    ./ports/starship.nix
  ];

  options.flowerTheme = {
    flower = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum flowerLib.flowers);
      default = null;
      description = "Flower applied to Helix, the terminals and the prompt; null keeps catppuccin.";
    };
  };
}
