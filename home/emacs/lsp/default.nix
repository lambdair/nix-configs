{ pkgs, epkgs }:
let
  eglot-booster = pkgs.callPackage ./eglot-booster {
    inherit (pkgs) fetchgit;
    inherit (pkgs.emacsPackages) trivialBuild;
  };
in
with epkgs;
[
  eglot
  eglot-booster
  lsp-mode
]
