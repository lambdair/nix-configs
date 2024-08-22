[
  # Telescope
  {
    action = "<cmd>Telescope find_files<CR>";
    key = "<leader>f";
  }
  {
    action = "<cmd>Telescope live_grep<CR>";
    key = "<leader>/";
  }
  {
    action = "<cmd>Telescope buffers<CR>";
    key = "<leader>b";
  }
  {
    action = "<cmd>Telescope help_tags<CR>";
    key = "<leader>hh";
  }
  {
    action = "<cmd>Telescope builtin<CR>";
    key = "<leader>?";
  }

  # Neotree
  {
    action = "<cmd>Neotree toggle<CR>";
    key = "<C-w>e";
  }

  # LSP
  {
    action = "<cmd>Telescope lsp_definitions<CR>";
    key = "gd";
  }
  {
    action = "<cmd>Telescope lsp_references<CR>";
    key = "gr";
  }
  {
    action = "<cmd>Telescope lsp_workspace_symbols<CR>";
    key = "<leader>s";
  }
  {
    action = "<cmd>lua vim.lsp.buf.hover()<CR>";
    key = "<leader>k";
  }
  {
    action = "<cmd>lua vim.lsp.buf.rename()<CR>";
    key = "<leader>r";
  }

  # LazyGit
  {
    action = "<cmd>LazyGit<CR>";
    key = "<leader>gg";
  }

  # Gitsigns
  {
    action = "<cmd>Gitsigns prev_hunk<CR>";
    key = "[g";
  }
  {
    action = "<cmd>Gitsigns next_hunk<CR>";
    key = "]g";
  }
  {
    action = "<cmd>Gitsigns preview_hunk<CR>";
    key = "<leader>gv";
  }
  {
    action = "<cmd>Gitsigns reset_hunk<CR>";
    key = "<leader>gr";
  }
]
