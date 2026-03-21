;;; init-config.el --- Shared Emacs configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; This file contains the shared Emacs configuration used across
;; both Nix-managed and Elpaca-managed (Windows) environments.
;; Loaded by init.el after environment-specific bootstrap.

;;; Code:

;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
;;; System Behavior
;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
(use-package files
  :ensure nil
  :config
  (auto-save-visited-mode 1))

(setq shell-file-name
      (if (eq system-type 'windows-nt)
          (or (executable-find "bash") "cmd.exe")
        (or (executable-find "bash") "/bin/bash")))
(setq use-short-answers 1)
(setq ring-bell-function 'ignore)
(setq scroll-conservatively 1)
(setq-default indent-tabs-mode nil)
(setq make-backup-files nil)
(setq backup-inhibited nil)
(setq create-lockfiles nil)

(use-package autorevert
  :ensure nil
  :config
  (global-auto-revert-mode 1))


;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
;;; UI
;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
(global-display-line-numbers-mode 1)
(setq display-line-numbers-type 'relative)
(scroll-bar-mode 0)
(tool-bar-mode 0)
(menu-bar-mode 0)
(setq-default show-trailing-whitespace 1)
(setq-default truncate-lines t)

(use-package paren
  :ensure nil
  :config
  (show-paren-mode 1)
  (set-face-background 'show-paren-match "#babbf1")
  (set-face-foreground 'show-paren-match "#303446"))

;; Font configuration
(cond
 ((eq system-type 'darwin)
  (set-face-attribute 'default nil
                      :family "Uiua386"
                      :height 160)
  (dolist (charset '(kana han cjk-misc))
    (set-fontset-font t charset
                      (font-spec :family "Rounded Mgen+ 2m"))))
 ((eq system-type 'windows-nt)
  ;; TODO: Configure Windows fonts
  nil)
 (t
  (add-to-list 'default-frame-alist '(font . "Uiua386-12"))
  (set-fontset-font "fontset-default"
                    'han "Rounded Mgen+ 2m")
  (set-fontset-font "fontset-default"
                    'kana "Rounded Mgen+ 2m")))

(use-package catppuccin-theme
  :demand t
  :config
  (setq catppuccin-flavor 'frappe)
  (load-theme 'catppuccin :no-confirm))

(use-package nord-theme)

(use-package dashboard
  :demand t
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

(use-package doom-modeline
  :demand t
  :config
  (doom-modeline-mode 1))

(use-package nerd-icons-completion
  :after (consult marginalia)
  :config
  (nerd-icons-completion-mode 1)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

(use-package neotree
  :config (setq neo-theme
                (if (display-graphic-p)
                    'nerd-icons
                  'arrow)))

;; resize-window (inline utility, no package)
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
(keymap-global-set "C-x w w" 'resize-window)


;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
;;; Key Bindings
;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
(defun goto-match-paren (arg)
  "Go to the matching parenthesis if on parenthesis, otherwise insert %.
vi style of % jumping to matching brace."
  (interactive "p")
  (cond ((looking-at "\\s\(") (forward-list 1) (backward-char 1))
        ((looking-at "\\s\)") (forward-char 1) (backward-list 1))
        (t nil)))
(keymap-global-set "<home>" 'beginning-of-line)
(keymap-global-set "<end>" 'end-of-line)

(use-package avy)

(use-package meow
  :demand t
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
     '("j" . "H-j")
     '("k" . "H-k")
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
  (meow-global-mode 1))

(use-package which-key
  :demand t
  :config
  (which-key-mode 1))

(use-package ace-window
  :bind* ("M-o" . ace-window)
  :config (setq aw-dispatch-always 1))


;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
;;; Consult
;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
(use-package consult
  :bind (("C-c M-x" . consult-mode-command)
         ("C-c h" . consult-history)
         ("C-c m" . consult-man)
         ("C-c i" . consult-info)
         ([remap Info-search] . consult-info)
         ("C-x M-:" . consult-complex-command)
         ("C-x b" . consult-buffer)
         ("C-x 4 b" . consult-buffer-other-window)
         ("C-x 5 b" . consult-buffer-other-frame)
         ("C-x t b" . consult-buffer-other-tab)
         ("C-x r b" . consult-bookmark)
         ("C-x p b" . consult-project-buffer)
         ("M-#" . consult-register-load)
         ("M-'" . consult-register-store)
         ("C-M-#" . consult-register)
         ("M-y" . consult-yank-pop)
         ("C-M-y" . consult-yank-from-kill-ring)
         ("M-g e" . consult-compile-error)
         ("M-g f" . consult-flymake)
         ("M-g g" . consult-goto-line)
         ("M-g M-g" . consult-goto-line)
         ("M-g o" . consult-outline)
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi)
         ("M-s d" . consult-fd)
         ("M-s c" . consult-locate)
         ("M-s g" . consult-grep)
         ("M-s G" . consult-git-grep)
         ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)
         ("M-s e" . consult-isearch-history)
         :map isearch-mode-map
         ("M-e" . consult-isearch-history)
         ("M-s e" . consult-isearch-history)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         :map minibuffer-local-map
         ("M-s" . consult-history)
         ("M-r" . consult-history))

  :hook (completion-list-mode . consult-preview-at-point-mode)

  :init
  (setq register-preview-delay 0.5
        register-preview-function #'consult-register-format)
  (advice-add #'register-preview :override #'consult-register-window)
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  :config
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file consult-xref
   consult-source-bookmark consult-source-file-register
   consult-source-recent-file consult-source-project-recent-file
   :preview-key '(:debounce 0.4 any))

  (setq consult-narrow-key "<")

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

(keymap-global-set "C-x C-b" 'ibuffer)


;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
;;; Search
;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
(use-package ctrlf
  :demand t
  :config
  (ctrlf-mode 1))

(use-package affe
  :config
  (defun affe-orderless-regexp-compiler (input _type _ignorecase)
    (setq input (cdr (orderless-compile input)))
    (cons input (apply-partially #'orderless--highlight input t)))
  (setq affe-regexp-compiler #'affe-orderless-regexp-compiler))


;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
;;; Tree-sitter
;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
(use-package treesit
  :ensure nil
  :config
  (add-to-list 'treesit-extra-load-path
               (expand-file-name "tree-sitter" user-emacs-directory)))


;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
;;; LSP
;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
(setq lsp-keymap-prefix "C-c l")

(use-package eglot-booster
  :demand t
  :after eglot
  :config (eglot-booster-mode))

(setenv "LSP_USE_PLISTS" "true")

(use-package lsp-mode
  :demand t
  :config
  (define-key lsp-mode-map (kbd "C-c l") lsp-command-map)
  (lsp-enable-which-key-integration t)
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
      (if (and (not test?)
               (not (file-remote-p default-directory))
               lsp-use-plists
               (not (functionp 'json-rpc-connection))
               (executable-find "emacs-lsp-booster"))
          (progn
            (when-let ((command-from-exec-path (executable-find (car orig-result))))
              (setcar orig-result command-from-exec-path))
            (message "Using emacs-lsp-booster for %s!" orig-result)
            (cons "emacs-lsp-booster" orig-result))
        orig-result)))
  (advice-add 'lsp-resolve-final-command :around #'lsp-booster--advice-final-command))


;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
;;; Editing
;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
(use-package puni)

(use-package expreg
  :bind
  ("C-=" . expreg-expand)
  ("C--" . expreg-contract))


;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
;;; Flymake
;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
(use-package flymake
  :ensure nil
  :bind (:map prog-mode-map
         ("M-N" . flymake-goto-next-error)
         ("M-P" . flymake-goto-prev-error)))


;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
;;; Completion
;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
(setq tab-always-indent 'complete)

(use-package vertico
  :demand t
  :config
  (vertico-mode 1))

(use-package marginalia
  :demand t
  :config
  (marginalia-mode 1))

(use-package corfu
  :demand t
  :after lsp-mode
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.3)
  (corfu-auto-prefix 1)
  (corfu-popupinfo-delay 0.3)
  (lsp-completion-provider :none)
  :config
  (global-corfu-mode 1)
  (require 'corfu-popupinfo)
  (corfu-popupinfo-mode 1)
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(use-package cape
  :bind ("C-c p" . cape-prefix-map)
  :init
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-elisp-block)
  (add-hook 'completion-at-point-functions #'cape-history))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))


;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
;;; Languages
;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

;; Lisp
(use-package eros
  :demand t
  :config
  (eros-mode 1))

(use-package aggressive-indent
  :hook (emacs-lisp-mode . aggressive-indent-mode))

(use-package lispy
  :demand t
  :config
  (define-key lispy-mode-map (kbd "M-.") nil)
  (add-hook 'clojure-mode-hook #'lispy-mode)
  (add-hook 'emacs-lisp-mode-hook #'lispy-mode)
  (add-hook 'scheme-mode-hook #'lispy-mode))

(use-package parinfer-rust-mode)

(use-package racket-mode
  :mode "\\.rkt\\'"
  :hook (racket-mode . racket-xp-mode))

(use-package clojure-mode
  :after lsp-mode
  :hook (clojure-mode . lsp))

(use-package cider
  :config
  (setq cider-repl-display-help-banner nil))

(use-package lean4-mode
  :demand t)

(setq auto-mode-alist (cons '("\\.pl\\'" . prolog-mode)
                            auto-mode-alist))

(use-package uiua-ts-mode
  :mode "\\.ua\\'"
  :hook (uiua-ts-mode . eglot-ensure)
  :config
  (add-to-list 'lsp-language-id-configuration '(uiua-ts-mode . "uiua"))
  (add-to-list 'lsp-language-id-configuration '(".*\\.ua$" . "uiua"))
  (lsp-register-client (make-lsp-client
                        :new-connection (lsp-stdio-connection '("uiua" "lsp"))
                        :activation-fn (lsp-activate-on "uiua")
                        :server-id 'uiua)))

(use-package bqn-mode
  :bind
  (:map bqn-mode-map
   ("C-c C-e" . bqn-comint-eval-dwim)
   ("C-c C-b" . bqn-comint-eval-buffer)
   ("C-c C-r" . bqn-comint-eval-region)
   ("C-c C-M-e" . bqn-comint-send-dwim)
   ("C-c C-M-b" . bqn-comint-send-buffer)
   ("C-c C-M-r" . bqn-comint-send-region)))

(use-package nix-mode
  :mode "\\.nix\\'"
  :hook (nix-mode . eglot-ensure))

(use-package typst-ts-mode
  :demand t
  :after eglot
  :mode "\\.typ\\'"
  :hook (typst-ts-mode . eglot-ensure)
  :config (add-to-list 'eglot-server-programs
                       `((typst-ts-mode) .
                         ,(eglot-alternatives `(,typst-ts-lsp-download-path
                                                "tinymist"
                                                "typst-lsp")))))


;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
;;; Environment
;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
(use-package exec-path-from-shell
  :if (not (eq system-type 'windows-nt))
  :demand t
  :custom
  (exec-path-from-shell-check-startup-files nil)
  (exec-path-from-shell-variables '("PATH" "JAVA_HOME" "OPENAI_API_TOKEN"))
  :config (exec-path-from-shell-initialize))

(use-package envrc
  :if (not (eq system-type 'windows-nt))
  :demand t
  :config
  (envrc-global-mode 1))


;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
;;; Version Control
;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
(use-package magit-delta
  :hook (magit-mode . magit-delta-mode)
  :custom
  (magit-delta-default-dark-theme "TwoDark"))

(use-package diff-hl
  :demand t
  :config
  (global-diff-hl-mode 1)
  :bind (:map prog-mode-map
         ("M-n" . diff-hl-next-hunk)
         ("M-p" . diff-hl-previous-hunk)))

(use-package jj-mode
  :demand t)


;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
;;; Org
;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
(use-package org-modern
  :demand t
  :config
  (global-org-modern-mode 1))


;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
;;; Integrations
;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
(use-package pdf-tools
  :if (not (eq system-type 'windows-nt))
  :mode "\\.pdf\\'"
  :hook
  (pdf-view-mode . (lambda ()
                      (display-line-numbers-mode 0)))
  :config
  (pdf-loader-install))

(use-package vterm
  :if (not (eq system-type 'windows-nt)))

(use-package copilot
  :bind (:map copilot-completion-map
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
    (add-to-list 'copilot-indentation-alist entry)))

;;; init-config.el ends here
