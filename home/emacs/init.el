;;; init.el --- My init.el -*- lexical-binding: t; -*-

;;; Commentary:

;;; Code:

;; activate leaf
;; Simplify your init.el configuration, extended use-package
(use-package leaf)

(leaf leaf-keywords
  :config
  (leaf-keywords-init))

(leaf leaf-tree
  :doc "Interactive side-bar feature for init.el using leaf"
  :bind (emacs-lisp-mode-map
         :package leaf
         ("C-c C-t" . leaf-tree-mode)))


(leaf system-behaivior
  :config
  (leaf files
    :doc "file input and output commands for Emacs"
    :global-minor-mode auto-save-visited-mode)

  (setq shell-file-name (or (executable-find "bash") "/bin/bash"))
  (setq use-short-answers 1)
  (setq ring-bell-function 'ignore)
  (setq scroll-conservatively 1)
  (setq-default indent-tabs-mode nil)
  (setq make-backup-files nil)
  (setq backup-inhibited nil)
  (setq create-lockfiles nil)

  (leaf autorevert
    :doc "revert buffers when files on disk change"
    :global-minor-mode global-auto-revert-mode))


(leaf ui
  :config
  (global-display-line-numbers-mode 1)
  (setq display-line-numbers-type 'relative)
  (scroll-bar-mode 0)
  (tool-bar-mode 0)
  (menu-bar-mode 0)
  (setq-default show-trailing-whitespace 1)
  (setq-default truncate-lines t)

  (leaf paren
    :doc "highlight matching paren"
    :config
    (show-paren-mode 1)
    (set-face-background 'show-paren-match "#babbf1")
    (set-face-foreground 'show-paren-match "#303446"))

  (leaf font
    :config
    (if (eq system-type 'darwin)
        (progn
          (set-face-attribute 'default nil
                              :family "Uiua386"
                              :height 160)
          (dolist (charset '(kana han cjk-misc))
            (set-fontset-font t charset
                              (font-spec :family "Rounded Mgen+ 2m"))))
          ;; (setq face-font-rescale-alist
          ;;       '(("Rounded.*" . 1.25)))
          
      (progn
        ;; (set-frame-font "Uiua386 12" nil t)
        (add-to-list 'default-frame-alist '(font . "Uiua386-12"))
        (set-fontset-font "fontset-default"
                          'han "Rounded Mgen+ 2m")
        (set-fontset-font "fontset-default"
                          'kana "Rounded Mgen+ 2m"))))

  (leaf catppuccin-theme
    :doc "Catppuccin for Emacs - 🍄 Soothing pastel theme for Emacs"
    :config
    (setq catppuccin-flavor 'frappe)
    ;; (setq catppuccin-flavor 'latte)
    (load-theme 'catppuccin :no-confirm))

  (leaf nord
    :doc "An arctic, north-bluish clean and elegant theme")
    ;; :config
    ;; (load-theme 'nord :no-confirm)
    

  (leaf dashboard
    :doc "A startup screen extracted from Spacemacs"
    :config
    (setq dashboard-set-file-icons t)
    (setq dashboard-set-heading-icons t)
    (setq dashboard-center-content t)
    (setq dashboard-startup-banner 'logo)
    (setq dashboard-icon-type 'nerd-icons)
    (setq dashboard-items '((recents  . 5)
                            (bookmarks . 5)
                            (projects . 5)
                            (agenda . 5)
                            (registers . 5)))
    (dashboard-setup-startup-hook))

  (leaf doom-modeline
    :doc "The core libraries for doom-modeline"
    :global-minor-mode doom-modeline-mode)

  (leaf nerd-icons-completion
    :doc "Add icons to completion candidates"
    :after consult marginalia
    :global-minor-mode nerd-icons-completion-mode
    :config (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

  (leaf neotree
    :doc "A tree plugin like NerdTree for Vim"
    :config (setq neo-theme
                  (if (display-graphic-p)
                      'nerd-icons
                    'arrow)))

  (leaf resize-window
    :config
    (defun resize-window (&optional arg)
      "Resize window interactively."
      (interactive "p")
      (if (one-window-p) (error "Cannot resize sole window"))
      (or arg (setq arg 1))
      (let (c)
        (catch 'done
          (while t
            (message
             "hl=horizontal, kj=vertical (by %d); 1-9=unit, q=quit"
             arg)
            (setq c (read-char))
            (condition-case ()
                (cond
                 ((= c ?k) (enlarge-window arg))
                 ((= c ?j) (shrink-window arg))
                 ((= c ?l) (enlarge-window-horizontally arg))
                 ((= c ?h) (shrink-window-horizontally arg))
                 ((= c ?\^G) (keyboard-quit))
                 ((= c ?q) (throw 'done t))
                 ((and (> c ?0) (<= c ?9)) (setq arg (- c ?0)))
                 (t (beep)))
              (error (beep)))))
        (message "Done.")))
    (keymap-global-set "C-x w w" 'resize-window)))

(leaf key-bindings
  :config
  (leaf my-key-bindings
    :config
    (defun goto-match-paren (arg)
      "Go to the matching parenthesis if on parenthesis, otherwise insert %.
vi style of % jumping to matching brace."
      (interactive "p")
      (cond ((looking-at "\\s\(") (forward-list 1) (backward-char 1))
            ((looking-at "\\s\)") (forward-char 1) (backward-list 1))
            (t nil)))
    (keymap-global-set "<home>" 'beginning-of-line)
    (keymap-global-set "<end>" 'end-of-line))

  (leaf avy
    :doc "Jump to things in Emacs tree-style")

  (leaf meow
    :doc "Yet Another modal editing"
    :require t
    :config
    (setq meow-use-clipboard t)
    (setq meow-expand-hint-counts nil)

    (defun meow-setup ()
      (setq meow-cheatsheet-layout meow-cheatsheet-layout-qwerty)
      (meow-motion-overwrite-define-key
       '("j" . meow-next)
       '("k" . meow-prev)
       '("<escape>" . ignore))
      (meow-leader-define-key
       ;; SPC j/k will run the original command in MOTION state.
       '("j" . "H-j")
       '("k" . "H-k")
       ;; Use SPC (0-9) for digit arguments.
       '("1" . meow-digit-argument)
       '("2" . meow-digit-argument)
       '("3" . meow-digit-argument)
       '("4" . meow-digit-argument)
       '("5" . meow-digit-argument)
       '("6" . meow-digit-argument)
       '("7" . meow-digit-argument)
       '("8" . meow-digit-argument)
       '("9" . meow-digit-argument)
       '("0" . meow-digit-argument)
       '("/" . meow-keypad-describe-key)
       '("?" . meow-cheatsheet)
       '("w" . ace-window))
      (meow-normal-define-key
       '("0" . meow-expand-0)
       '("9" . meow-expand-9)
       '("8" . meow-expand-8)
       '("7" . meow-expand-7)
       '("6" . meow-expand-6)
       '("5" . meow-expand-5)
       '("4" . meow-expand-4)
       '("3" . meow-expand-3)
       '("2" . meow-expand-2)
       '("1" . meow-expand-1)
       '("-" . negative-argument)
       '(";" . meow-reverse)
       '("," . meow-inner-of-thing)
       '("." . meow-bounds-of-thing)
       '("[" . meow-beginning-of-thing)
       '("]" . meow-end-of-thing)
       '("%" . goto-match-paren)
       '("a" . meow-append)
       '("A" . meow-open-below)
       '("b" . meow-back-word)
       '("B" . meow-back-symbol)
       '("c" . meow-change)
       '("d" . meow-delete)
       '("D" . meow-backward-delete)
       '("e" . meow-next-word)
       '("E" . meow-next-symbol)
       '("f" . meow-find)
       '("G" . meow-grab)
       '("h" . meow-left)
       '("H" . meow-left-expand)
       '("i" . meow-insert)
       '("I" . meow-open-above)
       '("j" . meow-next)
       '("J" . meow-next-expand)
       '("k" . meow-prev)
       '("K" . meow-prev-expand)
       '("l" . meow-right)
       '("L" . meow-right-expand)
       '("m" . meow-join)
       '("n" . meow-search)
       '("o" . meow-block)
       '("O" . meow-to-block)
       '("p" . meow-yank)
       '("q" . meow-quit)
       '("Q" . meow-cancel-selection)
       '("r" . meow-replace)
       '("R" . meow-swap-grab)
       '("s" . meow-kill)
       '("t" . meow-till)
       '("u" . meow-undo)
       '("U" . meow-undo-in-selection)
       '("v" . meow-visit)
       '("w" . meow-mark-word)
       '("W" . meow-mark-symbol)
       '("x" . meow-line)
       '("X" . meow-goto-line)
       '("y" . meow-save)
       '("Y" . meow-sync-grab)
       '("z" . meow-pop-selection)
       '("'" . repeat)
       '("<escape>" . ignore))
      ;; Define "g" as a prefix key
      (setq meow-g-keymap (make-sparse-keymap))
      (keymap-set meow-g-keymap "g" 'consult-goto-line)
      (keymap-set meow-g-keymap "w" 'avy-goto-word-0)
      (keymap-set meow-normal-state-keymap "g" meow-g-keymap))
    (meow-setup)
    :global-minor-mode meow-global-mode)

  (leaf which-key
    :doc "Display available keybindings in popup"
    :global-minor-mode which-key-mode)

  (leaf ace-window
    :doc "Quickly switch windows"
    :bind* ("M-o" . ace-window)
    :config (setq aw-dispatch-always 1)))


(use-package consult
  ;; Consulting completing-read
  ;; Replace bindings. Lazily loaded by `use-package'.
  :bind (;; C-c bindings in `mode-specific-map'
         ("C-c M-x" . consult-mode-command)
         ("C-c h" . consult-history)
         ;; ("C-c k" . consult-kmacro)
         ("C-c m" . consult-man)
         ("C-c i" . consult-info)
         ([remap Info-search] . consult-info)
         ;; C-x bindings in `ctl-x-map'
         ("C-x M-:" . consult-complex-command)
         ("C-x b" . consult-buffer)
         ("C-x 4 b" . consult-buffer-other-window)
         ("C-x 5 b" . consult-buffer-other-frame)
         ("C-x t b" . consult-buffer-other-tab)
         ("C-x r b" . consult-bookmark)
         ("C-x p b" . consult-project-buffer)
         ;; Custom M-# bindings for fast register access
         ("M-#" . consult-register-load)
         ("M-'" . consult-register-store)
         ("C-M-#" . consult-register)
         ;; Other custom bindings
         ("M-y" . consult-yank-pop)
         ("C-M-y" . consult-yank-from-kill-ring)
         ;; M-g bindings in `goto-map'
         ("M-g e" . consult-compile-error)
         ("M-g f" . consult-flymake)
         ("M-g g" . consult-goto-line)
         ("M-g M-g" . consult-goto-line)
         ("M-g o" . consult-outline) ;; Alternative: consult-org-heading
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi)
         ;; M-s bindings in `search-map'
         ("M-s d" . consult-fd)
         ("M-s c" . consult-locate)
         ("M-s g" . consult-grep)
         ("M-s G" . consult-git-grep)
         ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)
         ;; Isearch integration
         ("M-s e" . consult-isearch-history)
         :map isearch-mode-map
         ("M-e" . consult-isearch-history)
         ("M-s e" . consult-isearch-history)
         ("M-s l" . consult-line) ;; needed by consult-line to detect isearch
         ("M-s L" . consult-line-multi) ;; needed by consult-line to detect isearch
         ;; Minibuffer history
         :map minibuffer-local-map
         ("M-s" . consult-history) ;; orig. next-matching-history-element
         ("M-r" . consult-history)) ;; orig. previous-matching-history-element

  ;; Enable automatic preview at point in the *Completions* buffer. This is
  ;; relevant when you use the default completion UI.
  :hook (completion-list-mode . consult-preview-at-point-mode)

  ;; The :init configuration is always executed (Not lazy)
  :init

  ;; Optionally configure the register formatting. This improves the register
  ;; preview for `consult-register', `consult-register-load',
  ;; `consult-register-store' and the Emacs built-ins.
  (setq register-preview-delay 0.5
        register-preview-function #'consult-register-format)

  ;; Optionally tweak the register preview window.
  ;; This adds thin lines, sorting and hides the mode line of the window.
  (advice-add #'register-preview :override #'consult-register-window)

  ;; Use Consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  ;; Configure other variables and modes in the :config section,
  ;; after lazily loading the package.
  :config

  ;; Optionally configure preview. The default value
  ;; is 'any, such that any key triggers the preview.
  ;; (setq consult-preview-key 'any)
  ;; (setq consult-preview-key "M-.")
  ;; (setq consult-preview-key '("S-<down>" "S-<up>"))
  ;; For some commands and buffer sources it is useful to configure the
  ;; :preview-key on a per-command basis using the `consult-customize' macro.
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file consult-xref
   consult-source-bookmark consult-source-file-register
   consult-source-recent-file consult-source-project-recent-file
   ;; :preview-key "M-."
   :preview-key '(:debounce 0.4 any))

  ;; Optionally configure the narrowing key.
  ;; Both < and C-+ work reasonably well.
  (setq consult-narrow-key "<") ;; "C-+"

  ;; Optionally make narrowing help available in the minibuffer.
  ;; You may want to use `embark-prefix-help-command' or which-key instead.
  ;; (keymap-set consult-narrow-map (concat consult-narrow-key " ?") #'consult-narrow-help)

  ;; filter buffer
  (setq consult-buffer-filter
        '("\\` "
          "\\`\\*Help\\*\\'"
          "\\`\\*Warnings\\*\\'"
          "\\`\\*Messages\\*\\'"
          "\\`\\*Backtrace\\*\\'"
          "\\`\\*Async-native-compile-log\\*\\'"
          "\\`\\*EGLOT .*\\*\\'"
          "\\`magit-.*\\'"
          "\\`\\*vc\\*\\'"
          "\\`\\*vc-diff\\*.*\\'"
          "\\`\\*lsp-documentation\\*\\'"
          "\\`\\*lsp-log\\*\\'"
          "\\`\\*clojure-lsp.*\\*\\'"
          "\\`\\*nrepl-server.*\\'"
          "\\`\\*cider-doc\\*\\'"
          "\\`\\*cider-error\\*\\'"
          "\\`\\*diff-hl-show-hunk.*\\*\\'"
          "\\`\\*uiua.*\\*\\'"
          "\\`\\*Flymake.*\\*\\'")))

;; (leaf embark
;;   :doc "Conveniently act on minibuffer completions"
;;   :bind (minibuffer-mode-map
;;           ("M-." . embark-dwim)
;;           ("C-." . embark-act)))

;; (leaf embark-consult
;;   :doc "Consult integration for Embark"
;;   :hook (embark-collect-mode . consult-preview-at-point-mode))

(keymap-global-set "C-x C-b" 'ibuffer)

(leaf finder
  :config
  (leaf ctrlf
    :doc "Emacs finally learns how to ctrl+F"
    :global-minor-mode ctrlf-mode)

  (leaf affe
    :doc "Asynchronous Fuzzy Finder for Emacs"
    :config
    (defun affe-orderless-regexp-compiler (input _type _ignorecase)
      (setq input (cdr (orderless-compile input)))
      (cons input (apply-partially #'orderless--highlight input t)))
    (setq affe-regexp-compiler #'affe-orderless-regexp-compiler)))


(leaf treesit
  :config
  (add-to-list 'treesit-extra-load-path
               (expand-file-name "tree-sitter" user-emacs-directory)))


(setq lsp-keymap-prefix "C-c l")

(leaf lsp
  ;; (leaf eglot
  ;;   :doc "The Emacs Client for LSP servers"
  ;;   :config (add-hook 'prog-mode-hook #'eglot-ensure))

  (leaf eglot-booster
    :doc "Boost eglot using lsp-booster"
    :require t
    :after eglot
    :config (eglot-booster-mode))

  (setenv "LSP_USE_PLISTS" "true")

  (leaf lsp-mode
    :config
    (define-key lsp-mode-map (kbd "C-c l") lsp-command-map)
    (defun lsp-booster--advice-json-parse (old-fn &rest args)
      "Try to parse bytecode instead of json."
      (or
       (when (equal (following-char) ?#)
         (let ((bytecode (read (current-buffer))))
           (when (byte-code-function-p bytecode)
             (funcall bytecode))))
       (apply old-fn args)))
    (advice-add (if (progn (require 'json)
                           (fboundp 'json-parse-buffer))
                    'json-parse-buffer
                  'json-read)
                :around
                #'lsp-booster--advice-json-parse)

    (defun lsp-booster--advice-final-command (old-fn cmd &optional test?)
      "Prepend emacs-lsp-booster command to lsp CMD."
      (let ((orig-result (funcall old-fn cmd test?)))
        (if (and (not test?) ;; for check lsp-server-present?
                 (not (file-remote-p default-directory)) ;; see lsp-resolve-final-command, it would add extra shell wrapper
                 lsp-use-plists
                 (not (functionp 'json-rpc-connection)) ;; native json-rpc
                 (executable-find "emacs-lsp-booster"))
            (progn
              (when-let ((command-from-exec-path (executable-find (car orig-result)))) ;; resolve command from exec-path (in case not found in $PATH)
                (setcar orig-result command-from-exec-path))
              (message "Using emacs-lsp-booster for %s!" orig-result)
              (cons "emacs-lsp-booster" orig-result))
          orig-result)))
    (advice-add 'lsp-resolve-final-command :around #'lsp-booster--advice-final-command)))

(leaf edit-enhancement
  :config
  (leaf puni
    :doc "Parentheses Universalistic")

  (leaf expreg
    :doc "Simple expand region"
    :bind
    ("C-=" . expreg-expand)
    ("C--" . expreg-contract)))


(leaf flymake
  :doc "A universal on-the-fly syntax checker"
  :bind (prog-mode-map
         ("M-N" . flymake-goto-next-error)
         ("M-P" . flymake-goto-prev-error)))


(leaf completion
  :config
  (setq tab-always-indent 'complete)
  (leaf vertico
    :doc "VERTical Interactive COmpletion"
    :global-minor-mode vertico-mode)

  (leaf marginalia
    :doc "Enrich existing commands with completion annottions"
    :global-minor-mode marginalia-mode)

  (leaf corfu
    :doc "COmpletion in Region FUnction"
    :after lsp-mode
    :custom
    (corfu-auto . t)
    (corfu-auto-delay . 0.3)
    (corfu-auto-prefix . 1)
    (corfu-popupinfo-delay . 0.3)
    ;; for lsp-mode
    (lsp-completion-provider . :none)
    :config
    (global-corfu-mode 1)
    (corfu-popupinfo-mode 1)
    ;; nerd icons
    (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

  (use-package cape
    ;; Bind prefix keymap providing all Cape commands under a mnemonic key.
    ;; Press C-c p ? to for help.
    :bind ("C-c p" . cape-prefix-map) ;; Alternative keys: M-p, M-+, ...
    ;; Alternatively bind Cape commands individually.
    ;; :bind (("C-c p d" . cape-dabbrev)
    ;;        ("C-c p h" . cape-history)
    ;;        ("C-c p f" . cape-file)
    ;;        ...)
    :init
    ;; Add to the global default value of `completion-at-point-functions' which is
    ;; used by `completion-at-point'.  The order of the functions matters, the
    ;; first function returning a result wins.  Note that the list of buffer-local
    ;; completion functions takes precedence over the global list.
    (add-hook 'completion-at-point-functions #'cape-dabbrev)
    (add-hook 'completion-at-point-functions #'cape-file)
    (add-hook 'completion-at-point-functions #'cape-elisp-block)
    (add-hook 'completion-at-point-functions #'cape-history))

  (leaf orderless
    :doc "Completion style for matching regexps in any order"
    :custom
    (completion-styles . '(orderless basic))
    (completion-category-overrides . '((file (styles basic partial-completion))))))


(leaf languages
  :doc "Language specifics"
  :config

  ;; Lisp
  (leaf eros
    :doc "Evaluation Result OverlayS for Emacs Lisp"
    :global-minor-mode eros-mode)

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

  (leaf parinfer-rust-mode
    :doc "An interface for the parinfer-rust library")
    ;;   :config
    ;;   (add-hook 'clojure-mode-hook #'parinfer-rust-mode)
    ;;   (add-hook 'emacs-lisp-mode-hook #'parinfer-rust-mode)
    ;;   (add-hook 'scheme-mode-hook #'parinfer-rust-mode)
    

  (leaf racket-mode
    :doc "Racket editing, REPL, and more"
    :mode "\\.rkt\\'"
    :hook (racket-mode-hook . racket-xp-mode))

  (leaf clojure-mode
    :doc "Major mode for Clojure code"
    :after lsp-mode
    :hook (clojure-mode-hook . lsp))

  (leaf cider
    :doc "Clojure Interactive Development Environment that Rocks"
    :config
    (setq cider-repl-display-help-banner nil))

  ;;   (leaf clojure-ts-mode
  ;;     :doc "Major mode for Clojure code")

  ;;   (leaf sly
  ;;     :doc "Sylvester the Cat's Common Lisp IDE"
  ;;     :config (setq inferior-lisp-program "sbcl"))

  (leaf lean4-mode
    :doc "Major mode for Lean language"
    :require t)

  ;; (leaf nael
  ;;   :doc "Major mode for Lean language"
  ;;   :require t
  ;;   :config
  ;;   (keymap-set nael-mode-map "C-c ." #'highlight-symbol-at-point)
  ;;   (add-hook 'nael-mode-hook #'abbrev-mode)
  ;;   (add-hook 'nael-mode-hook #'eglot-ensure))

  (setq auto-mode-alist (cons '("\\.pl\\'" . prolog-mode)
                              auto-mode-alist))

  (leaf uiua-ts-mode
    :doc "Uiua treesiter mode"
    :mode "\\.ua\\'"
    :hook (uiua-ts-mode-hook . eglot-ensure)
    :config
    (add-to-list 'lsp-language-id-configuration '(uiua-ts-mode . "uiua"))
    (add-to-list 'lsp-language-id-configuration '(".*\\.ua$" . "uiua"))
    (lsp-register-client (make-lsp-client
                          :new-connection (lsp-stdio-connection '("uiua" "lsp"))
                          :activation-fn (lsp-activate-on "uiua")
                          :server-id 'uiua)))

  (leaf bqn-mode
    :doc "Emacs mode for BQN"
    :bind
    (bqn-mode-map
     ("C-c C-e" . bqn-comint-eval-dwim)
     ("C-c C-b" . bqn-comint-eval-buffer)
     ("C-c C-r" . bqn-comint-eval-region)
     ("C-c C-M-e" . bqn-comint-send-dwim)
     ("C-c C-M-b" . bqn-comint-send-buffer)
     ("C-c C-M-r" . bqn-comint-send-region)))

  (leaf nix-mode
    :doc "Major mode for Nix expressions, powered by tree-sitter"
    :mode "\\.nix\\'"
    :hook (nix-mode-hook . eglot-ensure)))

(leaf typst-ts-mode
  :doc "Tree Sitter support for Typst"
  :require t
  :after eglot
  :mode "\\.typ\\'"
  :hook (typst-ts-mode . eglot-ensure)
  :config (add-to-list 'eglot-server-programs
                       `((typst-ts-mode) .
                         ,(eglot-alternatives `(,typst-ts-lsp-download-path
                                                "tinymist"
                                                "typst-lsp")))))


(leaf exec-path-from-shell
  :doc "Get environment variables such as $PATH from the shell"
  :require t
  :custom ((exec-path-from-shell-check-startup-files)
           (exec-path-from-shell-variables . '("PATH" "JAVA_HOME" "OPENAI_API_TOKEN")))
  :config (exec-path-from-shell-initialize))

(leaf envrc
  :doc "Per-directory environment via direnv"
  :require t
  :global-minor-mode envrc-global-mode)


(leaf vc
  :config
  (leaf magit-delta
    ;; Use Delta when displaying diffs in Magit
    :hook
    (magit-mode . magit-delta-mode)
    :custom
    (magit.delta-default-dark-theme . "TwoDark"))

  (leaf diff-hl
    :doc "Highlight uncommitted changes using VC"
    :global-minor-mode global-diff-hl-mode
    :bind (prog-mode-map
           ("M-n" . diff-hl-next-hunk)
           ("M-p" . diff-hl-previous-hunk)))

  (leaf jj-mode
    :require t
    :doc "A jujutsu vcs mode inspired by magit"))

(leaf org
  :config
  (leaf org-modern
    :doc "Modern looks for Org"
    :global-minor-mode global-org-modern-mode))


(leaf integrations
  :config
  (leaf pdf-tools
    :doc "Support library for PDF documents"
    :mode "\\.pdf\\'"
    :hook
    (pdf-view-mode-hook . (lambda ()
                            (display-line-numbers-mode 0)))
    :config
    (pdf-loader-install))

  (leaf vterm
    :doc "Fully-featured terminal emulator")

  (leaf copilot
    :doc "An unofficial Copilot plugin for Emacs"
    :bind (copilot-completion-map
           ("<tab>" . copilot-accept-completion))
    :config
    (dolist (entry '((nix-mode . 2)
                     (typst-ts-mode . 2)
                     (uiua-ts-mode . 2)
                     (lean4-mode . 2)
                     (clojure-mode . 2)
                     (emacs-lisp-mode . 2)
                     (rust-mode . 4)
                     (rust-ts-mode . 4)
                     (typescript-mode . 2)
                     (typescript-ts-mode . 2)
                     (tsx-ts-mode . 2)))
      (add-to-list 'copilot-indentation-alist entry))))
    ;; (global-copilot-mode)
    
;;; init.el ends here
