# Colour themes after the costumes of ヰ世界情緒 (Anemone, Nemophila,
# Sunflower), each in dark and light.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.flowerTheme;
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
    specialisations = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Build every flower variant as a specialisation, so `flower` can switch to it without a rebuild.";
    };
  };

  config = lib.mkIf (cfg.flower != null && cfg.specialisations) {
    specialisation = lib.listToAttrs (
      map (
        v:
        lib.nameValuePair v.name {
          configuration.flowerTheme = {
            flower = lib.mkForce v.flower;
            mode = lib.mkForce v.mode;
          };
        }
      ) flowerLib.variants
    );

    home.packages = [
      # Named flower so the generated --help shows `flower` as the command.
      (pkgs.writeScriptBin "flower" ''
        #!${lib.getExe pkgs.nushell} --no-config-file
        ${builtins.readFile ./flower.nu}
      '')
    ];
  };
}
