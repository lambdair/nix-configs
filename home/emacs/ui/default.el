(leaf neotree
  :doc "A tree plugin like NerdTree for Vim"
  :config (setq neo-theme
		(if (display-graphic-p)
		    'nerd-icons
		    'arrow)))
