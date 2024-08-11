(leaf eglot
  :doc "The Emacs Client for LSP servers"
  :config (add-hook 'prog-mode-hook #'eglot-ensure))
