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

    plugins = importPlugins ./plugins // {
      dashboard.enable = true;
      web-devicons.enable = true;
      lualine.enable = true;
      neo-tree.enable = true;
      oil.enable = true;

      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          mapping = {
            "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
            "<Down>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
            "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
            "<Up>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            "<C-b>" = "cmp.mapping.scroll_docs(-4)";
            "<C-e>" = "cmp.mapping.abort()";
            "<C-Space>" = "cmp.mapping.complete()";
          };
          sources = [
            { name = "nvim_lsp"; }
            { name = "latex_symbols"; }
            { name = "buffer"; }
            { name = "path"; }
            { name = "copilot"; }
          ];
        };
      };
      cmp-nvim-lsp.enable = true;
      cmp-latex-symbols.enable = true;
      cmp-buffer.enable = true;
      cmp-path.enable = true;
      copilot-cmp.enable = true;

      copilot-lua = {
        enable = true;
        panel.enabled = false;
        suggestion.enabled = false;
      };

      mini.enable = true;
      which-key = {
        enable = true;
      };

      gitsigns.enable = true;
      diffview.enable = true;
      lazygit.enable = true;
      neogit.enable = true;

      nvim-autopairs = {
        enable = true;
        settings.disable_filetype = [ "clojure" ];
      };
      parinfer-rust.enable = true;

      treesitter = {
        enable = true;
        settings.highlight.enable = true;
      };
      nix.enable = true;
      lean = {
        enable = true;
        mappings = true;
        abbreviations.leader = ",";
      };
      conjure.enable = true;
    };

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
