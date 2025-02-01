{ pkgs, sources, ... }:

let
  # Import all plugins from the directory
  importPlugins =
    dir:
    let
      pluginNames = builtins.attrNames (builtins.readDir dir);
      plugins = builtins.filter (name: builtins.pathExists (dir + "/${name}/default.el")) pluginNames;
    in
    builtins.foldl' (acc: name: acc + builtins.readFile (dir + "/${name}/default.el")) "" plugins;
in
{
  programs.emacs = {
    enable = true;
    package = pkgs.emacs-git;
    extraConfig =
      builtins.readFile ./init.el
      + importPlugins ./ui
      + importPlugins ./navigation
      + importPlugins ./language
      + importPlugins ./lsp;
    extraPackages =
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
  };
  # home.file.".emacs.d/tree-sitter/libtree-sitter-typst.so".source =
  #   "${typst-ts-mode}/share/emacs/site-lisp/tree-sitter/libtree-sitter-typst.so";
}
