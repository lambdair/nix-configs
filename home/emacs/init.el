;;; init.el --- Entry point -*- lexical-binding: t; -*-

;;; Commentary:
;; Environment detection and bootstrap.
;; Loads init-config.el which contains the shared configuration.

;;; Code:
(defvar my/nix-p (string-prefix-p "/nix/store/" invocation-directory)
  "Non-nil when running in a Nix-managed environment.")

;; Nix: disable :ensure entirely (packages are provided by Nix)
(when my/nix-p
  (setq use-package-always-ensure nil)
  (setq use-package-ensure-function 'ignore))

;; Non-Nix: bootstrap Elpaca and enable use-package integration
(unless my/nix-p
  (defvar elpaca-installer-version 0.11)
  (defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
  (defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
  (defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
  (defvar elpaca-order
    '(elpaca :repo "https://github.com/progfolio/elpaca.git"
             :ref nil :depth 1 :inherit t
             :files (:defaults "elpaca-test.el" (:exclude "extensions"))
             :build (:not elpaca--hierarchical-resolve)))
  (let* ((repo (expand-file-name "elpaca/" elpaca-repos-directory))
         (build (expand-file-name "elpaca/" elpaca-builds-directory))
         (order (cdr elpaca-order))
         (default-directory repo))
    (add-to-list 'load-path (if (file-exists-p build) build repo))
    (unless (file-exists-p repo)
      (make-directory repo t)
      (condition-case-unless-debug err
          (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                    ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                    ,@(when-let* ((depth (plist-get order :depth)))
                                                        (list (format "--depth=%d" depth) "--no-single-branch"))
                                                    ,(plist-get order :repo) ,repo))))
                    ((zerop (call-process "git" nil buffer t "checkout"
                                          (or (plist-get order :ref) "--"))))
                    (emacs (concat invocation-directory invocation-name))
                    ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                          "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                    ((require 'elpaca))
                    ((elpaca-generate-autoloads "elpaca" repo)))
              (progn (message "%s" (buffer-string)) (kill-buffer buffer))
            (error "%s" (with-current-buffer buffer (buffer-string))))
        ((error) (warn "%s" err) (delete-directory repo 'recursive))))
    (unless (require 'elpaca-autoloads nil t)
      (require 'elpaca)
      (elpaca-generate-autoloads "elpaca" repo)
      (load "./elpaca-autoloads")))
  (add-hook 'after-init-hook #'elpaca-process-queues)
  (elpaca `(,@elpaca-order))

  ;; use-package integration
  (elpaca elpaca-use-package
    (elpaca-use-package-mode))
  (setq use-package-always-ensure t)

  ;; Custom packages not on MELPA/ELPA
  (elpaca (jj-mode :host github :repo "bolivier/jj-mode.el"))
  (elpaca (lean4-mode :host github :repo "leanprover-community/lean4-mode"))
  (elpaca (typst-ts-mode :host nil :repo "https://codeberg.org/meow_king/typst-ts-mode"))
  (elpaca (eglot-booster :host github :repo "jdtsmith/eglot-booster"))

  ;; Tree-sitter grammar auto-install (Nix uses home.file symlinks instead)
  (elpaca treesit-auto
    (setq treesit-auto-install 'prompt)
    (global-treesit-auto-mode))

  (elpaca-wait))

;; Load shared configuration
(load (expand-file-name "init-config" user-emacs-directory))

;;; init.el ends here
