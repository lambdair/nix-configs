;; plugin settings
;; UI
(let [nordic (require :nordic)]
  (nordic.load))

(let [lualine (require :lualine)]
  (lualine.setup {:options {:theme "nordic"}}))

(let [gitsigns (require :gitsigns)]
  (gitsigns.setup {}))

;; LSP (nvim 0.11+ native API)
(let [cmp_lsp (require :cmp_nvim_lsp)
      capabilities (cmp_lsp.default_capabilities)]
  (vim.lsp.config :* {:capabilities capabilities}))

(vim.lsp.enable [:fennel_ls :racket_langserver :nil_ls :uiua])

(let [cmp (require :cmp)]
  (cmp.setup {:sources [{:name "nvim_lsp"}
                        {:name "buffer"}
                        {:name "path"}
                        {:name "conjure"}]}))

(let [lean (require :lean)]
  (lean.setup {:mappings true}))

;; options
(local opt vim.opt)
(set opt.number true)
(set opt.relativenumber true)

(set opt.tabstop 2)
(set opt.shiftwidth 2)
(set opt.expandtab true)

;; map
(set vim.g.mapleader " ")
(set vim.g.maplocalleader ",")

(local map vim.api.nvim_set_keymap)
(map :i "jj" "<esc>" {:noremap true})

(map :n "<leader>f" "<cmd>FzfLua files<cr>" {:noremap true})
(map :n "<leader>b" "<cmd>FzfLua buffers<cr>" {:noremap  true})
(map :n "<leader>/" "<cmd>FzfLua live_grep_native<cr>" {:noremap true})
(map :n "<leader>?" "<cmd>FzfLua<cr>" {:noremap true})
(map :n "<leader>g" "<cmd>Neogit<cr>" {:noremap true})

(map :n "<leader>k" "<cmd>lua vim.lsp.buf.hover()<cr>" {:noremap true})
(map :n "gd" "<cmd>FzfLua lsp_definitions<cr>" {:noremap true})
(map :n "gr" "<cmd>FzfLua lsp_references<cr>" {:noremap true})

(map :n "<C-w><C-w>" "<cmd>SmartResizeMode<cr>" {:noremap true})
