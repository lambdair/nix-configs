[
  {
    action = "<cmd>FzfLua files<CR>";
    key = "<leader>f";
    options.desc = "Find files";
  }
  {
    action = "<cmd>FzfLua live_grep_native<CR>";
    key = "<leader>/";
    options.desc = "Live grep";
  }
  {
    action = "<cmd>FzfLua buffers<CR>";
    key = "<leader>bb";
    options.desc = "Buffers";
  }
  {
    action = "<cmd>FzfLua lgrep_curbuf<CR>";
    key = "<leader>b/";
    options.desc = "Live grep (buffer)";
  }
  {
    action = "<cmd>FzfLua helptags<CR>";
    key = "<leader>hh";
    options.desc = "Help tags";
  }
  {
    action = "<cmd>FzfLua builtin<CR>";
    key = "<leader>?";
    options.desc = "Command palette";
  }

  # LSP
  {
    action = "<cmd>FzfLua lsp_definitions<CR>";
    key = "gd";
    options.desc = "Goto definition";
  }
  {
    action = "<cmd>FzfLua lsp_references<CR>";
    key = "gr";
    options.desc = "References";
  }
  {
    action = "<cmd>FzfLua lsp_document_symbols<CR>";
    key = "<leader>s";
    options.desc = "Symbols";
  }
]
