{
  pkgs,
  sources,
  inputs,
  ...
}:

let
  # neomacs loads dynamic modules but does not register the error symbols a
  # failed load signals, so it raises `(error "Invalid error symbol" ...)`
  # instead of a condition a handler can match.
  moduleErrorSymbols = pkgs.writeText "neomacs-module-errors.el" ''
    (unless (get 'module-open-failed 'error-conditions)
      (define-error 'module-load-failed "Module load failed")
      (define-error 'module-open-failed "Module could not be opened" 'module-load-failed)
      (define-error 'module-init-failed "Module initialization failed" 'module-load-failed)
      (define-error 'module-not-gpl-compatible "Module is not GPL compatible" 'module-load-failed))
  '';
  neomacs = inputs.neomacs.packages.${pkgs.stdenv.hostPlatform.system}.default;
  # nixpkgs' elisp builders expect two things neomacs's package lacks: the
  # setup hook that puts each dependency on EMACSLOADPATH, and meta.platforms.
  # A symlink shim adds them and leaves neomacs's own derivation (the one in
  # eval-exec.cachix.org) untouched.  neomacs also ships emacs/emacsclient as
  # aliases of neomacs/neomacsclient.
  emacs = pkgs.symlinkJoin {
    pname = "neomacs-shim";
    inherit (neomacs) version;
    paths = [ neomacs ];
    postBuild = ''
      rm -f $out/nix-support/setup-hook
      install -Dm644 ${pkgs.path}/pkgs/applications/editors/emacs/setup-hook.sh \
        $out/nix-support/setup-hook
    '';
    passthru = { inherit (neomacs) src; };
    meta = neomacs.meta // {
      platforms = pkgs.lib.platforms.unix;
    };
  };
in
{
  home.packages = [
    (pkgs.emacsWithPackagesFromUsePackage {
      package = emacs;
      config = ./init-config.el;
      defaultInitFile = false;
      # Overrides go through the package scope, so the transitive dependants of
      # a patched package pick the patched build up too.
      override = _final: prev: {
        # tsc guards its optional load of tsc-dyn with a `module-open-failed`
        # handler, which never matches under neomacs. Removable once neomacs
        # registers the symbols itself.
        tsc = prev.tsc.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            # The file's first line carries its lexical-binding cookie, which
            # only counts there, so the shim goes on the second.
            head -n 1 core/tsc-dyn-get.el > guarded.el
            cat ${moduleErrorSymbols} >> guarded.el
            tail -n +2 core/tsc-dyn-get.el >> guarded.el
            mv guarded.el core/tsc-dyn-get.el
          '';
        });
        # neomacs's byte-compiler ignores the lexical environment alist `eval`
        # takes, so markdown--dotimes-when-compile expands its generated
        # defface forms with the loop variable unbound. Binding it with `let`
        # produces the same expansion under both compilers. Removable once
        # neomacs honours the alist.
        markdown-mode = prev.markdown-mode.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            substituteInPlace markdown-mode.el \
              --replace-fail \
                '(push (eval body `((,var . ,i))) code))' \
                '(push (eval `(let ((,var ,i)) ,body) t) code))'
          '';
        });
      };
      extraEmacsPackages =
        epkgs:
        let
          # Single canonical lsp-mode build with plist support enabled at
          # byte-compile time. Shared so every consumer (./lsp module and
          # lean4-mode in ./language) references the same store path —
          # otherwise lndir merges multiple lsp-mode builds and the
          # unmodified one wins, undoing the override.
          lsp-mode-plist = epkgs.lsp-mode.overrideAttrs (old: {
            env = (old.env or { }) // {
              LSP_USE_PLISTS = "true";
            };
          });
        in
        with epkgs;
        (import ./ui { inherit pkgs epkgs sources; })
        ++ (import ./navigation { inherit epkgs; })
        ++ (import ./language {
          inherit
            pkgs
            epkgs
            sources
            lsp-mode-plist
            ;
        })
        ++ (import ./lsp {
          inherit
            pkgs
            epkgs
            sources
            lsp-mode-plist
            ;
        })
        ++ [
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          # Package Configuration
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          eros

          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          # UI / Help
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          dirvish
          helpful

          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          # Modal Editing
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          meow

          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          # Completion
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          vertico
          marginalia
          consult
          embark
          embark-consult
          corfu
          nerd-icons-corfu
          cape
          orderless

          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          # Version Control
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          magit
          magit-delta
          diff-hl

          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          # Editing / Formatting
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          expreg
          puni
          aggressive-indent
          apheleia
          unicode-math-input

          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          # Search
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          ctrlf
          affe
          migemo

          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          # Language Support
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          pkgs.tree-sitter-grammars.tree-sitter-typescript
          pkgs.tree-sitter-grammars.tree-sitter-tsx
          pkgs.tree-sitter-grammars.tree-sitter-graphql
          tree-sitter-langs
          graphql-ts-mode

          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          # Environment
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          exec-path-from-shell
          envrc

          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          # Org
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          org-modern

          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          # Tools
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          rg
          pdf-tools
          vterm

          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          # AI
          # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          copilot
          claude-code
          # copilot-chat
        ];

    })
  ];
  # Emacs config files
  home.file.".emacs.d/init.el".source = ./init.el;
  home.file.".emacs.d/init-config.el".source = ./init-config.el;

  # Tree-sitter parser binaries
  home.file.".emacs.d/tree-sitter/libtree-sitter-typescript.so".source =
    "${pkgs.tree-sitter-grammars.tree-sitter-typescript}/parser";
  home.file.".emacs.d/tree-sitter/libtree-sitter-tsx.so".source =
    "${pkgs.tree-sitter-grammars.tree-sitter-tsx}/parser";
  home.file.".emacs.d/tree-sitter/libtree-sitter-graphql.so".source =
    "${pkgs.tree-sitter-grammars.tree-sitter-graphql}/parser";
  home.file.".emacs.d/tree-sitter/libtree-sitter-uiua.so" = {
    source = "${pkgs.tree-sitter-grammars.tree-sitter-uiua}/parser";
  };
  home.file.".emacs.d/tree-sitter/libtree-sitter-typst.so" = {
    source = "${pkgs.tree-sitter-grammars.tree-sitter-typst}/parser";
  };
}
