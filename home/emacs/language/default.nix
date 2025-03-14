{
  pkgs,
  epkgs,
  sources,
}:
let
  nael = pkgs.callPackage ./lean/nael.nix {
    inherit (pkgs) fetchgit;
    inherit (pkgs.emacsPackages) trivialBuild markdown-mode;
    inherit sources;
  };
  lean4-mode = pkgs.callPackage ./lean/lean4-mode.nix {
    inherit (pkgs.emacsPackages)
      trivialBuild
      markdown-mode
      dash
      lsp-mode
      compat
      magit-section
      ;
    inherit sources;
  };
  typst-ts-mode = pkgs.callPackage ./typst/typst-ts-mode.nix {
    inherit (pkgs) fetchgit;
    inherit (pkgs.emacsPackages) trivialBuild;
    inherit sources;
  };
in
with epkgs;
[
  # lean
  nael
  lean4-mode

  # lisp family
  lispy
  parinfer-rust-mode

  # emacs lipy
  eros
  macrostep

  # clojure
  clojure-ts-mode
  clojure-mode
  cider

  # scheme
  geiser
  geiser-guile
  geiser-racket

  # common lisp
  sly

  # nix
  nix-mode

  # uiua
  uiua-mode

  # prolog
  prolog-mode
  ediprolog

  # typst
  # typst-ts-mode

  # etc
  maude-mode
]
