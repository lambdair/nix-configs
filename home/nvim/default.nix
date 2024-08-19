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

      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          mapping = {
            "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
            "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            "<C-b>" = "cmp.mapping.scroll_docs(-4)";
            "<C-e>" = "cmp.mapping.abort()";
            "<C-Space>" = "cmp.mapping.complete()";
          };
          sources = [
            { name = "nvim_lsp"; }
            { name = "latex_symbols"; }
          ];
        };
      };
      cmp-nvim-lsp.enable = true;
      cmp-latex-symbols.enable = true;

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
