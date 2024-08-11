(leaf lean4-mode
  :doc "Major mode for Lean language"
  :require t)

(leaf nael
  :doc "A humble major-mode for Lean"
  :require t
  :after eglot
  :config
  (defun my-nael-setup ()
    (interactive)
    ;; Enable Emacs' built-in `TeX' input-method.  Alternatively, you
    ;; could install the external `unicode-math-input' package and
    ;; use the `unicode-math' input-method.
    ;; (set-input-method "TeX")
    (set-input-method "unicode-math")
    ;; Enable Emacs' built-in LSP-client Eglot.
    (eglot-ensure))

  (add-hook 'nael-mode-hook #'my-nael-setup)

  :bind
  (nael-mode-map
   ;; Nael buffer-locally sets `compile-command' to "lake build".
   ("C-c C-c" . project-compile)

   ;; Find out how to type the character at point in the current
   ;; input-method.
   ("C-c C-k" . quail-show-key)))
