{
  pkgs,
  epkgs,
  sources,
}:
let
  eglot-booster = pkgs.callPackage ./eglot-booster.nix {
    inherit (pkgs.emacsPackages) trivialBuild;
    inherit sources;
  };
in
with epkgs;
[
  eglot
  eglot-booster
  lsp-mode
]
