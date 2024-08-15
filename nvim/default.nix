{
  programs.nixvim = {
    enable = true;

    colorschemes.catppuccin = {
      enable = true;
      settings.flavour = "frappe";
    };

    opts = {
      number = true;
    };

    globals = {
      mapleader = " ";
      maplocalleader = ",";
    };

    luaLoader.enable = true;

    plugins = {
      telescope = {
        enable = true;
        extensions = {
          fzf-native.enable = true;
        };
        keymaps = {
          "<leader>f" = "find_files";
          "<leader>/" = "live_grep";
          "<leader>b" = "buffers";
          "<leader>hh" = "help_tags";
          "<leader>?" = "builtin";
        };
      };
      dashboard.enable = true;
      lualine.enable = true;
      neo-tree.enable = true;
      oil.enable = true;

      lsp = {
        enable = true;
        servers = {
          nil-ls.enable = true;
          clojure-lsp.enable = true;
        };
      };

      cmp.enable = true;

      mini.enable = true;
      which-key = {
        enable = true;
      };

      treesitter.enable = true;
      nix.enable = true;
      lean = {
        enable = true;
        mappings = true;
      };
      conjure.enable = true;
    };
  };
}
