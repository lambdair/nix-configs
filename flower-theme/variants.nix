# Every flower variant as one JSON file, the input of check.bb.
{ pkgs }:
pkgs.writeText "flower-variants.json" (
  builtins.toJSON (import ./lib.nix { inherit (pkgs) lib; }).variants
)
