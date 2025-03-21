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
      fzf-lua

      ## ui
      which-key-nvim
      lualine-nvim
      (pkgs.vimUtils.buildVimPlugin {
        name = "nordic";
        version = sources.nordic.version;
        src = sources.nordic.src;
      })
      nvim-web-devicons
      gitsigns-nvim
      neo-tree-nvim
      smart-splits-nvim

      ## completion
      nvim-cmp

      ## language
      nvim-lspconfig
      lean-nvim
      parinfer-rust
      vim-racket
      conjure
      nfnl
      markview-nvim

      ## git
      diffview-nvim
      neogit

      ## ai
      copilot-lua
    ];
    extraLuaConfig = builtins.readFile ./init.lua;
  };

  programs.nixvim = {
    enable = false;

    colorscheme = "nordic";
    colorschemes = {
      catppuccin = {
        enable = true;
        settings.flavour = "frappe";
      };
      tokyonight.enable = true;
      nord.enable = true;
    };

    opts = {
      relativenumber = true;
    };

    globals = {
      mapleader = " ";
      maplocalleader = ",";

      "conjure#mapping#doc_word" = false;
      "conjure#filetype#scheme" = "conjure.client.guile.socket";
      "elin_default_key_mapping_leader" = "<LocalLeader>";
      "elin_enable_default_key_mappings" = true;
    };

    luaLoader.enable = true;

    extraConfigLua = ''
      local lspconfig = require('lspconfig')
      lspconfig.uiua.setup{}

      require("render-markdown").setup({})
    '';

    filetype.extension = {
      ua = "uiua";
    };

    plugins = importPlugins ./plugins;
    extraPlugins = importExtraPlugins ./extra-plugins;

    keymaps = import ./keymaps.nix ++ importKeymaps ./plugins;
  };
}
