-- plugin settings
-- UI
require('nordic').load()
require('lualine').setup({
  options = {
    theme = 'nordic'
  }
})
require('gitsigns').setup()
require('lspconfig').racket_langserver.setup({})
require('lspconfig').nil_ls.setup({})

-- options
local opt = vim.opt
opt.number = true
opt.relativenumber = true

opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true

-- map
vim.g.mapleader = ' '
vim.g.maplocalleader = ','

local map = vim.api.nvim_set_keymap
map('i', 'jj', '<esc>', { noremap = true })

map('n', '<leader>f', '<cmd>FzfLua files<cr>', { noremap = true })
map('n', '<leader>b', '<cmd>FzfLua buffers<cr>', { noremap = true })
map('n', '<leader>/', '<cmd>FzfLua live_grep_native<cr>', { noremap = true })
map('n', '<leader>?', '<cmd>FzfLua<cr>', { noremap = true })
map('n', '<leader>g', '<cmd>Neogit<cr>', { noremap = true })

map('n', '<leader>k', '<cmd>lua vim.lsp.buf.hover()<cr>', { noremap = true })
map('n', 'gd', '<cmd>FzfLua lsp_definitions<cr>', { noremap = true })
map('n', 'gr', '<cmd>FzfLua lsp_references<cr>', { noremap = true })
