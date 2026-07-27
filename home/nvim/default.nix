{ pkgs, sources, ... }:
let
  # Import all plugins from the directory
  importPlugins =
    dir:
    let
      pluginNames = builtins.attrNames (builtins.readDir dir);
      plugins = builtins.filter (name: builtins.pathExists (dir + "/${name}/default.nix")) pluginNames;
    in
    builtins.foldl' (acc: name: acc // import (dir + "/${name}")) { } plugins;

  # Import all extra plugins from the directory
  importExtraPlugins =
    dir:
    let
      pluginNames = builtins.attrNames (builtins.readDir dir);
      plugins = builtins.filter (name: builtins.pathExists (dir + "/${name}/default.nix")) pluginNames;
    in
    builtins.map (name: import (dir + "/${name}") { inherit pkgs; }) plugins;

  # Import all keymaps from the directory
  importKeymaps =
    dir:
    let
      pluginNames = builtins.attrNames (builtins.readDir dir);
      keymapFiles = builtins.filter (
        name: builtins.pathExists (dir + "/${name}/keymaps.nix")
      ) pluginNames;
    in
    builtins.foldl' (acc: name: acc ++ import (dir + "/${name}/keymaps.nix")) [ ] keymapFiles;
in
{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # UI
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      which-key-nvim
      lualine-nvim
      (pkgs.vimUtils.buildVimPlugin {
        name = "nordic";
        version = sources.nordic.version;
        src = sources.nordic.src;
      })
      nvim-web-devicons
      mini-icons
      gitsigns-nvim
      neo-tree-nvim
      smart-splits-nvim

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Completion
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      copilot-cmp
      cmp-conjure

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Language Support
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      nvim-lspconfig
      nvim-treesitter
      nvim-treesitter-parsers.racket
      nvim-treesitter-parsers.fennel
      # nvim-treesitter-parsers has no prolog parser, so build it from the
      # tree-sitter grammar (parser + its bundled queries).
      (pkgs.runCommandLocal "vimplugin-treesitter-parser-prolog" { } ''
        mkdir -p "$out/parser" "$out/queries/prolog"
        cp ${pkgs.tree-sitter.builtGrammars.tree-sitter-prolog}/parser "$out/parser/prolog.so"
        cp ${pkgs.tree-sitter.builtGrammars.tree-sitter-prolog}/queries/*.scm "$out/queries/prolog/"
      '')
      lean-nvim
      parinfer-rust
      vim-racket
      conjure
      nfnl
      markview-nvim
      (pkgs.vimUtils.buildVimPlugin {
        name = "uiua";
        version = sources.uiua.version;
        src = sources.uiua.src;
      })
      (pkgs.vimUtils.buildVimPlugin {
        name = "nvim-bqn";
        version = sources.nvim-bqn.version;
        src = sources.nvim-bqn.src;
      })

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Search
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      fzf-lua

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Version Control
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      diffview-nvim
      neogit

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # AI
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      copilot-lua

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Library
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      plenary-nvim
    ];
    initLua = builtins.readFile ./init.lua;
  };
}
