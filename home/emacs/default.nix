{ pkgs, sources, ... }:

{
  home.packages = [
    (pkgs.emacsWithPackagesFromUsePackage {
      package = pkgs.emacs-git;
      config = ./init.el;
      defaultInitFile = true;
      extraEmacsPackages =
        epkgs:
        with epkgs;
        (import ./ui { inherit epkgs; })
        ++ (import ./navigation { inherit epkgs; })
        ++ (import ./language { inherit pkgs epkgs sources; })
        ++ (import ./lsp { inherit pkgs epkgs sources; })
        ++ [
          eros

          magit
          magit-delta
          diff-hl

          meow

          # completion
          vertico
          marginalia
          consult
          embark
          embark-consult
          corfu
          nerd-icons-corfu
          cape
          orderless

          leaf
          leaf-keywords
          leaf-tree

          apheleia

          # lang
          tree-sitter-langs

          expreg
          puni
          migemo
          unicode-math-input
          aggressive-indent

          ctrlf
          affe

          exec-path-from-shell

          # org
          org-modern

          # tool
          pdf-tools
          vterm

          # ai
          copilot
        ];

    })
  ];
  # home.file.".emacs.d/tree-sitter/libtree-sitter-typst.so".source =
  #   "${typst-ts-mode}/share/emacs/site-lisp/tree-sitter/libtree-sitter-typst.so";
}
