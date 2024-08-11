(leaf neotree
  :doc "A tree plugin like NerdTree for Vim"
  :config (setq neo-theme
		(if (display-graphic-p)
		    'nerd-icons
		    'arrow)))

(leaf catppuccin-theme
  :doc "Catppuccin for Emacs - 🍄 Soothing pastel theme for Emacs"
  :config
  (setq catppuccin-flavor 'frappe)
  ;; (setq catppuccin-flavor 'latte)
  (load-theme 'catppuccin :no-confirm))
