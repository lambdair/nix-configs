[
  # Neotree
  {
    action = "<cmd>Neotree toggle<CR>";
    key = "<C-w>e";
    options.desc = "Neotree";
  }

  # LazyGit
  {
    action = "<cmd>LazyGit<CR>";
    key = "<leader>gG";
  }

  # Neogit
  {
    action = "<cmd>Neogit<CR>";
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

  # Diffview
  {
    action = "<cmd>DiffviewOpen<CR>";
    key = "<leader>gd";
    options.desc = "Open Diffview";
  }
  {
    action = "<cmd>DiffviewClose<CR>";
    key = "<leader>gD";
    options.desc = "Close Diffview";
  }

  # Tab
  {
    action = "<cmd>tabnew<CR>";
    key = "<leader>tn";
    options.desc = "New tab";
  }
  {
    action = "<cmd>tabclose<CR>";
    key = "<leader>td";
    options.desc = "Close tab";
  }
]
