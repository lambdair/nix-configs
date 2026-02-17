-- [nfnl] init.fnl
do
  local nordic = require("nordic")
  nordic.load()
end
do
  local lualine = require("lualine")
  lualine.setup({options = {theme = "nordic"}})
end
do
  local gitsigns = require("gitsigns")
  gitsigns.setup({})
end
do
  local cmp_lsp = require("cmp_nvim_lsp")
  local capabilities = cmp_lsp.default_capabilities()
  vim.lsp.config("*", {capabilities = capabilities})
end
vim.lsp.enable({"fennel_ls", "racket_langserver", "nil_ls", "uiua"})
do
  local cmp = require("cmp")
  cmp.setup({sources = {{name = "nvim_lsp"}, {name = "buffer"}, {name = "path"}, {name = "conjure"}}})
end
do
  local lean = require("lean")
  lean.setup({mappings = true})
end
local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
vim.g.mapleader = " "
vim.g.maplocalleader = ","
local map = vim.api.nvim_set_keymap
map("i", "jj", "<esc>", {noremap = true})
map("n", "<leader>f", "<cmd>FzfLua files<cr>", {noremap = true})
map("n", "<leader>b", "<cmd>FzfLua buffers<cr>", {noremap = true})
map("n", "<leader>/", "<cmd>FzfLua live_grep_native<cr>", {noremap = true})
map("n", "<leader>?", "<cmd>FzfLua<cr>", {noremap = true})
map("n", "<leader>g", "<cmd>Neogit<cr>", {noremap = true})
map("n", "<leader>k", "<cmd>lua vim.lsp.buf.hover()<cr>", {noremap = true})
map("n", "gd", "<cmd>FzfLua lsp_definitions<cr>", {noremap = true})
map("n", "gr", "<cmd>FzfLua lsp_references<cr>", {noremap = true})
return map("n", "<C-w><C-w>", "<cmd>SmartResizeMode<cr>", {noremap = true})
