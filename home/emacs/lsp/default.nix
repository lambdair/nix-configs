{
  pkgs,
  epkgs,
  sources,
}:
let
  eglot-booster = pkgs.callPackage ./eglot-booster.nix {
    inherit (pkgs.emacs.pkgs) trivialBuild;
    inherit sources;
  };
  lsp-proxy = pkgs.callPackage ./lsp-proxy.nix {
    inherit (pkgs.emacs.pkgs) trivialBuild;
    inherit sources;
  };
  lsp-mode-plist = epkgs.lsp-mode.overrideAttrs (_: {
    LSP_USE_PLISTS = "true";
  });
in
with epkgs;
[
  eglot
  eglot-booster
  lsp-mode-plist
  # lsp-proxy
]
