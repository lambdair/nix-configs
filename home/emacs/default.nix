{ pkgs, sources, ... }:

{
  home.packages = [
    (pkgs.emacsWithPackagesFromUsePackage {
      package = if pkgs.stdenv.isLinux then pkgs.emacs-pgtk else pkgs.emacs-git;
      config = ./init.el;
      defaultInitFile = true;
      extraEmacsPackages =
        epkgs:
        with epkgs;
        (import ./ui { inherit pkgs epkgs sources; })
        ++ (import ./navigation { inherit epkgs; })
        ++ (import ./language { inherit pkgs epkgs sources; })
        ++ (import ./lsp { inherit pkgs epkgs sources; })
        ++ [
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          # Package Configuration
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          leaf
          leaf-keywords
          leaf-tree
          eros

          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          # UI / Help
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          dirvish
          helpful

          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          # Modal Editing
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          meow

          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          # Completion
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          vertico
          marginalia
          consult
          embark
          embark-consult
          corfu
          nerd-icons-corfu
          cape
          orderless

          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          # Version Control
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          magit
          magit-delta
          diff-hl

          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          # Editing / Formatting
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          expreg
          puni
          aggressive-indent
          apheleia
          unicode-math-input

          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          # Search
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          ctrlf
          affe
          migemo

          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          # Language Support
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          pkgs.tree-sitter-grammars.tree-sitter-typescript
          pkgs.tree-sitter-grammars.tree-sitter-tsx
          pkgs.tree-sitter-grammars.tree-sitter-graphql
          tree-sitter-langs
          graphql-ts-mode

          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          # Environment
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          exec-path-from-shell
          envrc

          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          # Org
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          org-modern

          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          # Tools
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          rg
          pdf-tools
          vterm

          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          # AI
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          copilot
          claude-code
          # copilot-chat
        ];

    })
  ];
  # Tree-sitter parser binaries
  home.file.".emacs.d/tree-sitter/libtree-sitter-typescript.so".source =
    "${pkgs.tree-sitter-grammars.tree-sitter-typescript}/parser";
  home.file.".emacs.d/tree-sitter/libtree-sitter-tsx.so".source =
    "${pkgs.tree-sitter-grammars.tree-sitter-tsx}/parser";
  home.file.".emacs.d/tree-sitter/libtree-sitter-graphql.so".source =
    "${pkgs.tree-sitter-grammars.tree-sitter-graphql}/parser";
  home.file.".emacs.d/tree-sitter/libtree-sitter-uiua.so" = {
    source = "${pkgs.tree-sitter-grammars.tree-sitter-uiua}/parser";
  };
  home.file.".emacs.d/tree-sitter/libtree-sitter-typst.so" = {
    source = "${pkgs.tree-sitter-grammars.tree-sitter-typst}/parser";
  };
}
