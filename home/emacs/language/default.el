(leaf aggressive-indent-mode
  :doc "Minor mode to aggressively keep your code always indented"
  :hook (emacs-lisp-mode . aggressive-indent-mode))

(leaf lispy
  :doc "vi-like Paredit"
  :require t
  :config
  (define-key lispy-mode-map (kbd "M-.") nil)
  (add-hook 'clojure-mode-hook #'lispy-mode)
  (add-hook 'emacs-lisp-mode-hook #'lispy-mode)
  (add-hook 'scheme-mode-hook #'lispy-mode))
