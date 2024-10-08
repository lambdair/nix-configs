{ pkgs, ... }:
let
  # Import all plugins from the directory
  importPlugins =
    dir:
    let
      pluginNames = builtins.attrNames (builtins.readDir dir);
      plugins = builtins.filter (name: builtins.pathExists (dir + "/${name}/default.nix")) pluginNames;
    in
    builtins.foldl' (acc: name: acc // import (dir + "/${name}")) { } plugins;

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
  programs.nixvim = {
    enable = true;

    colorscheme = "catppuccin";
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
    };

    luaLoader.enable = true;

    keymaps = import ./keymaps.nix ++ importKeymaps ./plugins;

    extraConfigLua = ''
      local lspconfig = require('lspconfig')
      lspconfig.uiua.setup{}

      require("render-markdown").setup({})
    '';

    filetype.extension = {
      ua = "uiua";
    };

    plugins = importPlugins ./plugins;

    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "render-markdown-nvim";
        src = pkgs.fetchFromGitHub {
          owner = "MeanderingProgrammer";
          repo = "render-markdown.nvim";
          rev = "d8be43719a09c82647ead778b607cd904202b670";
          sha256 = "sha256-4nkhlKEEJ4xK7wfVpq7kBFJlap5RhRFx8pup2FvIa+4=";
        };
      })
    ];
  };
}
