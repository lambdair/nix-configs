{
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
}
