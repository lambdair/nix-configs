[
  # Telescope
  {
    action = "<cmd>Telescope find_files<CR>";
    key = "<leader>f";
    options.desc = "Find files";
  }
  {
    action = "<cmd>Telescope live_grep<CR>";
    key = "<leader>/";
    options.desc = "Live grep";
  }
  {
    action = "<cmd>Telescope buffers<CR>";
    key = "<leader>b";
    options.desc = "Buffers";
  }
  {
    action = "<cmd>Telescope help_tags<CR>";
    key = "<leader>hh";
    options.desc = "Help tags";
  }
  {
    action = "<cmd>Telescope builtin<CR>";
    key = "<leader>?";
    options.desc = "Command palette";
  }

  # Neotree
  {
    action = "<cmd>Neotree toggle<CR>";
    key = "<C-w>e";
    options.desc = "Neotree";
  }

  # LSP
  {
    action = "<cmd>Telescope lsp_definitions<CR>";
    key = "gd";
    options.desc = "Goto definition";
  }
  {
    action = "<cmd>Telescope lsp_references<CR>";
    key = "gr";
    options.desc = "References";
  }
  {
    action = "<cmd>Telescope lsp_workspace_symbols<CR>";
    key = "<leader>s";
    options.desc = "Symbols";
  }
  {
    action = "<cmd>lua vim.lsp.buf.hover()<CR>";
    key = "<leader>k";
    options.desc = "Show docs";
  }
  {
    action = "<cmd>lua vim.lsp.buf.rename()<CR>";
    key = "<leader>r";
    options.desc = "Rename symbol";
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
    options.desc = "Previous change";
  }
  {
    action = "<cmd>Gitsigns next_hunk<CR>";
    key = "]g";
    options.desc = "Next change";
  }
  {
    action = "<cmd>Gitsigns preview_hunk<CR>";
    key = "<leader>gv";
    options.desc = "Preview change";
  }
  {
    action = "<cmd>Gitsigns reset_hunk<CR>";
    key = "<leader>gr";
    options.desc = "Reset change";
  }
]
