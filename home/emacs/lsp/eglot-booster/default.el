(leaf eglot-booster
  :doc "Boost eglot using lsp-booster"
  :require t
  :after eglot
  :config (eglot-booster-mode))
