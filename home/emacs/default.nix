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
          pkgs.tree-sitter-grammars.tree-sitter-typescript
          pkgs.tree-sitter-grammars.tree-sitter-tsx
          pkgs.tree-sitter-grammars.tree-sitter-graphql
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
          graphql-ts-mode

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
  home.file.".emacs.d/tree-sitter/libtree-sitter-typescript.so".source =
    "${pkgs.tree-sitter-grammars.tree-sitter-typescript}/parser";
  home.file.".emacs.d/tree-sitter/libtree-sitter-tsx.so".source =
    "${pkgs.tree-sitter-grammars.tree-sitter-tsx}/parser";
  home.file.".emacs.d/tree-sitter/libtree-sitter-graphql.so".source =
    "${pkgs.tree-sitter-grammars.tree-sitter-graphql}/parser";
  home.file.".emacs.d/tree-sitter/libtree-sitter-uiua.so" = {
    source = "${pkgs.tree-sitter-grammars.tree-sitter-uiua}/parser";
  };
  # home.file.".emacs.d/tree-sitter/libtree-sitter-typst.so".source =
  #   "${typst-ts-mode}/share/emacs/site-lisp/tree-sitter/libtree-sitter-typst.so";
}
