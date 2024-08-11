{
  trivialBuild,
  fetchgit,
  pkgs,
  sources,
}:

trivialBuild {
  pname = "typst-ts-mode";
  version = sources.typst-ts-mode.version;
  src = sources.typst-ts-mode.src;
  packageRequires = [ ];
  preBuild = ''
    mkdir -p $out/share/emacs/site-lisp/tree-sitter
    cp ${pkgs.tree-sitter-grammars.tree-sitter-typst}/parser $out/share/emacs/site-lisp/tree-sitter/libtree-sitter-typst.so
    cp ${pkgs.tree-sitter-grammars.tree-sitter-typst}/parser $HOME/.emacs.d/tree-sitter/libtree-sitter-typst.so
  '';
}
