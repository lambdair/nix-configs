{
  pkgs,
  epkgs,
  sources,
}:
let
  lean4-mode = pkgs.callPackage ./lean/lean4-mode.nix {
    inherit (pkgs.emacs.pkgs)
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
    inherit (pkgs.emacs.pkgs) trivialBuild;
    inherit sources;
  };
in
with epkgs;
[
  # lean
  lean4-mode
  nael

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
  # geiser-racket

  # racket
  racket-mode

  # common lisp
  sly

  # nix
  nix-mode

  # uiua
  uiua-ts-mode
  bqn-mode
  dyalog-mode

  # prolog
  prolog-mode
  ediprolog

  # typst
  typst-ts-mode

  # etc
  maude-mode
]
