(leaf typst-ts-mode
  :doc "Tree Sitter support for Typst"
  :after eglot
  :mode "\\.typ\\'"
  :config (add-to-list 'eglot-server-programs
		       `((typst-ts-mode) .
			 ,(eglot-alternatives `(,typst-ts-lsp-download-path
						"tinymist"
						"typst-lsp")))))
