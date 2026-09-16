# Loads the flower palettes and resolves each variant's roles and ANSI slots
# to hex.
{ lib }:
let
  palettes = ./palettes;

  # The directory is absent until the first palette is added.
  flowers =
    if builtins.pathExists palettes then
      map (lib.removeSuffix ".toml") (
        builtins.filter (lib.hasSuffix ".toml") (builtins.attrNames (builtins.readDir palettes))
      )
    else
      [ ];

  modes = [
    "dark"
    "light"
  ];

  ansiSlots = [
    "black"
    "red"
    "green"
    "yellow"
    "blue"
    "magenta"
    "cyan"
    "white"
    "bright-black"
    "bright-red"
    "bright-green"
    "bright-yellow"
    "bright-blue"
    "bright-magenta"
    "bright-cyan"
    "bright-white"
  ];

  # Mode for a port holding a single theme: auto shows the dark variant, the
  # choice Helix's fallback theme already makes.
  resolve = mode: if mode == "auto" then "dark" else mode;

  # sRGB blend of two hex colours, `ratio` being the weight of `b`. Diff line
  # backgrounds are made this way, since the palettes carry diff foregrounds.
  mix =
    ratio: a: b:
    let
      channel = hex: i: lib.fromHexString (builtins.substring (1 + 2 * i) 2 hex);
      blended =
        i:
        let
          value = (1.0 - ratio) * (channel a i) + ratio * (channel b i);
        in
        lib.fixedWidthString 2 "0" (lib.toHexString (builtins.floor (value + 0.5)));
    in
    "#"
    + lib.concatMapStrings blended [
      0
      1
      2
    ];

  variant =
    flower: mode:
    let
      palette = builtins.fromTOML (builtins.readFile (palettes + "/${flower}.toml"));
      v = palette.${mode};
      hex = name: v.colors.${name}.hex;
    in
    {
      name = "flower-${flower}-${mode}";
      inherit flower mode;
      title = "${palette.name} ${if mode == "dark" then "Dark" else "Light"}";
      inherit (palette) strand;
      inherit (v) colors roles ansi;
      hex = {
        roles = lib.mapAttrs (_: hex) v.roles;
        ansi = lib.mapAttrs (_: hex) v.ansi;
      };
    };
in
{
  inherit
    flowers
    modes
    ansiSlots
    variant
    resolve
    mix
    ;
  variants = lib.concatMap (flower: map (variant flower) modes) flowers;
}
