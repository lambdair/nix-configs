{
  pkgs,
  epkgs,
  sources,
  lsp-mode-plist,
}:
let
  eglot-booster = pkgs.callPackage ./eglot-booster.nix {
    inherit (pkgs.emacs.pkgs) trivialBuild;
    inherit sources;
  };
in
with epkgs;
[
  eglot
  eglot-booster
  lsp-mode-plist
]
