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
    ./ports/jjui.nix
    ./ports/hunk.nix
    ./ports/claude-code.nix
    ./ports/nushell.nix
    ./ports/fzf.nix
    ./ports/television.nix
    ./ports/delta.nix
    ./ports/yazi.nix
    ./ports/lazygit.nix
    ./ports/zellij.nix
  ];

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
