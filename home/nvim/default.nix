{ pkgs, sources, ... }:

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
      mini-icons
      gitsigns-nvim
      neo-tree-nvim
      smart-splits-nvim

      ## completion
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      copilot-cmp
      cmp-conjure

      ## language
      nvim-lspconfig
      nvim-treesitter
      nvim-treesitter-parsers.racket
      nvim-treesitter-parsers.fennel
      nvim-treesitter-parsers.prolog
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

      ## git
      diffview-nvim
      neogit

      ## ai
      copilot-lua

      ## lib
      plenary-nvim
    ];
    extraLuaConfig = builtins.readFile ./init.lua;
  };
}
