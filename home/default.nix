{
  pkgs,
  lib,
  sources,
  inputs,
  ...
}:
let
  inherit (import ../pkgs { inherit pkgs sources; })
    budget_tracker_tui
    lightpanda
    racket-with-langserver
    ;

  # jj wrapped with a betterleaks secret-scan gate on `jj git push`.
  # jj runs no git hooks and jjui execs `jj git push` directly, so wrapping
  # the binary is the only place a local scan fires for every push path.
  # See ./jj-push-guard.sh for the rationale and behaviour.
  betterleaksGuardedJj =
    (pkgs.symlinkJoin {
      name = "jujutsu-betterleaks-guarded-${pkgs.jujutsu.version}";
      paths = [ pkgs.jujutsu ];
      postBuild = ''
        rm $out/bin/jj
        substitute ${./jj-push-guard.sh} $out/bin/jj \
          --replace-fail '@jj@' ${pkgs.jujutsu}/bin/jj \
          --replace-fail '@betterleaks@' ${pkgs.betterleaks}/bin/betterleaks
        chmod +x $out/bin/jj
      '';
    })
    // {
      # Preserve version + meta (incl. meta.mainProgram) so the home-manager
      # jujutsu module's version checks and `getExe` keep working.
      inherit (pkgs.jujutsu) version meta;
    };

  # jj additionally wrapped with a serialization lock (see ./jj-lock.zig for the
  # mechanism), nested outside the betterleaks guard so the whole invocation is
  # serialized against a repo-shared flock. Without it, jj processes sharing one
  # op log can fork it into a divergent change.
  lockSerializedJj =
    (pkgs.symlinkJoin {
      name = "jujutsu-serialized-${pkgs.jujutsu.version}";
      paths = [ betterleaksGuardedJj ];
      nativeBuildInputs = [ pkgs.zig_0_16 ];
      postBuild = ''
        rm $out/bin/jj
        export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-cache"
        substitute ${./jj-lock.zig} jj-lock.zig \
          --replace-fail '@REAL_JJ@' '${betterleaksGuardedJj}/bin/jj'
        zig build-exe -lc -O ReleaseSmall -femit-bin=$out/bin/jj jj-lock.zig
      '';
    })
    // {
      inherit (pkgs.jujutsu) version meta;
    };
in
{
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  home.packages =
    with pkgs;
    [
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Array Languages / APL Family
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      uiua-unstable # Stack-based array programming language
      tree-sitter-grammars.tree-sitter-uiua # Tree-sitter grammar for Uiua
      # tree-sitter-grammars.tree-sitter-bqn
      cbqn # BQN implementation in C
      # (dyalog.override { acceptLicense = true; })
      ride # Remote IDE for Dyalog APL

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Nix Development
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      nil # Yet another language server for Nix
      nixfmt # Official formatter for Nix code
      nix-search # Search nixpkgs
      nix-tree # Interactively browse Nix store paths dependencies
      nix-update # Swiss-knife for updating nix packages
      nvfetcher # Generate nix sources expr for the latest version of packages
      devenv # Fast, Declarative, Reproducible, and Composable Developer Environments

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Web Development (TS/JS)
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      nodejs # Node.js JavaScript runtime
      typescript-language-server # TypeScript/JavaScript language server
      tailwindcss-language-server # Tailwind CSS language server

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Rust Development
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      rust-bin.stable.latest.default # Rust toolchain (stable)
      rust-analyzer # Modular compiler frontend for the Rust language

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # MoonBit Development
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # `.latest` is pinned by the overlay's versions JSON, so it moves only on
      # `just update`; the toolchain bundles core at build time, so nothing is
      # downloaded into ~/.moon at runtime.
      moonbit-bin.moonbit.latest # MoonBit toolchain (moon, moonc, moonrun, moon-lsp)

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Zig Development
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      zig # Zig toolchain (compiler, build system, fmt)
      zls # Zig language server

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Python Development
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # macOS /usr/bin/python3 is an xcrun shim that fails when DEVELOPER_DIR points at a nix SDK
      python3 # Python interpreter
      uv # Fast Python package installer and resolver
      python312Packages.pylatexenc # LaTeX encoder for Python

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Theorem Proving / Formal Verification
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # isabelle
      maude # High-level specification language
      # teyjus # Efficient implementation of Lambda Prolog

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Lisp / Scheme
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # sbcl
      racket-with-langserver # Racket, with racket-langserver on its collection path
      guile # Embeddable Scheme implementation

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Clojure / Fennel
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      clojure # Dynamic, general-purpose programming language on the JVM
      clojure-lsp # Language Server Protocol (LSP) for Clojure
      clj-kondo # Linter for Clojure code that sparks joy
      cljfmt # Tool for formatting Clojure code
      cljstyle # Clojure code formatter
      babashka # Clojure babushka for the grey areas of Bash
      fennel-ls # Language server for Fennel Programming Language
      fnlfmt # Formatter for Fennel

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Logic Programming
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # scryer-prolog
      swi-prolog # Prolog compiler and interpreter
      # ciao

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Document Preparation / Typesetting
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      typst # New markup-based typesetting system
      typstyle # Format your typst source code
      tinymist # Integrated language service for Typst

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # File Search / File Management
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ripgrep # Fast grep alternative (rg)
      fd # Simple, fast alternative to find
      superfile # Pretty fancy and modern terminal file manager
      dust # du + rust = dust. More intuitive disk usage

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Git / Version Control
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      gitu # TUI Git client inspired by Magit
      tig # Text-mode interface for git
      lazyjj # TUI for Jujutsu/jj
      jjui # TUI for Jujutsu
      github-cli # GitHub CLI (gh)
      gh-dash # GitHub CLI extension for PR/issue dashboard
      git-secrets # Prevents committing secrets and credentials (git only; not triggered by jj)
      betterleaks # Secret scanner (Gitleaks successor); gates `jj git push` via betterleaksGuardedJj wrapper
      giff # Terminal-based Git diff viewer
      inputs.hunk.packages.${pkgs.stdenv.hostPlatform.system}.default # Review-first terminal diff viewer for agentic coders

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Development Tools
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      tldr # Simplified and community-driven man pages
      emacs-lsp-booster # Emacs LSP performance booster
      parinfer-rust-emacs # Emacs centric fork of parinfer-rust
      typos-lsp # Source code spell checker
      zoekt # Fast trigram based code search
      graphviz # Graph visualization tools
      go-migrate # Database migrations
      jq # Command-line JSON processor
      ansifilter # ANSI escape code filter
      rlwrap # Readline wrapper for interactive programs
      codex # OpenAI Codex CLI

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Database
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      rainfrog # Database management TUI for PostgreSQL
      lazysql # Terminal client for MySQL, PostgreSQL, SQLite
      sqldef # Idempotent SQL schema management tool

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Docker / Containers
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      oxker # Simple TUI to view & control docker containers
      lazydocker # Simple terminal UI for docker and docker-compose

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # System Monitoring
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      btop # Monitor of resources

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Media / Music
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      spotify-player # Terminal spotify player with feature parity
      mcat # cat for documents, images and videos
      alda # Music programming language

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Web / Mail / HTTP
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      posting # HTTP client TUI
      xh # Friendly and fast HTTP request tool
      himalaya # CLI to manage emails
      w3m # Text-mode web browser
      chawan # Lightweight terminal web browser
      lightpanda # Headless browser for agents (JS, CDP, MCP)
      ngrok # Secure tunnels to localhost

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Notes / Knowledge Management
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      nb # Command line note-taking and knowledge base
      rucola # Terminal-based markdown note manager
      basalt # TUI for managing Obsidian notes
      tdf # TUI-based PDF viewer
      glow # Render markdown on the CLI
      sdcv # StarDict console version
      wordnet # Lexical database for English

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Finance Management
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      budget_tracker_tui # TUI budget tracking application
      bagels # TUI expense tracker

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Other CLI Utilities
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      just # Command runner
      pik # Process interactive kill
      xan # CSV toolkit
      tuios # Terminal-based window manager
      enchant # Generic spell checking library
      aws-vault # AWS credential management
      ssm-session-manager-plugin # AWS SSM Session Manager
      bitwarden-cli # Bitwarden CLI (bw) for credential retrieval

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Fonts
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      nerd-fonts.hack
      nerd-fonts.sauce-code-pro
      nerd-fonts.symbols-only
      julia-mono
      rounded-mgenplus
      maple-mono.NF-CN
      uiua386
      apl386
      bqn386
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      abella # Interactive theorem prover (Linux only: darwin build fails on ocaml-4.12.1 thread tests)
      d2 # Modern diagram scripting language (Linux only: darwin build fails on libdrm/mesa-libgbm)
      dict # Dictionary client (Linux only: darwin build fails on dictd → flex 2.5.35 K&R C)
    ];

  imports = [
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Editors
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ./helix.nix # Post-modern modal text editor (hx)
    ./helix-steel.nix # Helix with the Steel plugin runtime
    ./nvim # Vim fork focused on extensibility and agility
    ./emacs # Extensible, customizable text editor

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Git / Version Control
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ./difit.nix # Browser-based git diff viewer
    ./jj-megamerge.nix # Rebuild helper for the jj megamerge workflow

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # File Search / File Management
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ./elio.nix # Terminal file manager (Rust/Ratatui)
    ./television.nix # Fuzzy finder TUI (tv)

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Development Tools
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ./claude # AI coding assistant in the terminal
  ];

  catppuccin = {
    flavor = "frappe";
    enable = true;
    autoEnable = true;
    nvim.enable = false;
  };

  programs = {
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Terminal Emulators
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # GPU-accelerated terminal emulator and multiplexer
    wezterm = {
      enable = true;
      extraConfig = builtins.readFile ./wezterm.lua;
    };

    # GPU-based terminal emulator
    kitty = {
      enable = true;
      font.name = "Uiua386";
    };

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Shell
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Structured-data shell (nu)
    nushell = {
      enable = true;
      shellAliases = {
        ze = "zellij";
        lg = "lazygit";
        e = "emacs";
        ee = "emacsclient -r";
        et = "emacsclient -nw -a hx";
        es = "emacs --daemon";
        ek = "emacsclient -e '(kill-emacs)'";
        vi = "nvim";
        uu = "uiua repl";
        cl = "claude";
        hr = "bb ~/.claude/skills/reviewing-jj-revisions-with-hunk/hr";
        nrepl = "clj -Sdeps '{:deps {cider/cider-nrepl {:mvn/version \"0.52.0\"} }}' -m nrepl.cmdline --middleware \"[cider.nrepl/cider-middleware]\"";
      };
      environmentVariables = {
        EDITOR = "hx";
      };
      configFile.source = ./config.nu;
    };

    # Multi-shell command argument completer
    carapace.enable = true;
    carapace.enableNushellIntegration = true;

    # Cross-shell prompt
    starship = {
      enable = true;
    };

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # File Navigation / Viewing
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Directory jumper that learns your habits (z)
    zoxide = {
      enable = true;
      enableNushellIntegration = true;
    };

    # cat(1) clone with syntax highlighting and git integration
    bat = {
      enable = true;
    };

    # Command-line fuzzy finder
    fzf = {
      enable = true;
    };

    # Terminal file manager
    yazi = {
      enable = true;
    };

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Git / Version Control
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Distributed version control system
    git = {
      enable = true;
      settings = {
        user.email = "lambdair1984@protonmail.com";
        user.name = "Lambdair";
        core.pager = "hunk pager";
      };
    };

    # Syntax-highlighting diff pager
    delta = {
      enable = true;
      enableGitIntegration = false;
    };

    # Git-compatible DVCS (jj)
    jujutsu = {
      enable = true;
      package = lockSerializedJj;
      settings = {
        user.email = "lambdair1984@protonmail.com";
        user.name = "Lambdair";
        ui.pager = [
          "hunk"
          "pager"
        ];
        ui.diff-formatter = ":git";
      };
    };

    # Terminal UI for git
    lazygit = {
      enable = true;
      settings = {
        os.editPreset = "nvim";
      };
    };

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Development Tools
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Per-directory environment loader
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Terminal Multiplexer
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Terminal workspace and multiplexer
    zellij = {
      enable = true;
    };

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Media / Music
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # ncurses Spotify client
    ncspot = {
      enable = true;
      settings = {
        use_nerdfont = true;
      };
    };
  };

  home.file.".clojure/deps.edn".source = ./deps.edn;

  xdg.configFile."jjui/config.toml".text = ''
    [[actions]]
    name = "show-diff-in-hunk"
    desc = "show diff in hunk"
    lua = ''''
    local change_id = context.change_id()
    if not change_id or change_id == "" then
      flash({ text = "No revision selected", error = true })
      return
    end
    exec_shell(string.format("jj diff -r %q --git --color always | hunk pager", change_id))
    ''''
    key = "H"
    scope = "revisions"

    # Review the selected revision by opening it in difit (in the browser).
    [[actions]]
    name = "difit-review"
    desc = "review revision in difit"
    lua = ''''
    local commit_id = context.commit_id()
    if not commit_id or commit_id == "" then
      flash({ text = "No revision selected", error = true })
      return
    end
    exec_shell(string.format("difit %q", commit_id))
    ''''
    key = "V"
    scope = "revisions"

    [[actions]]
    name = "megamerge-rebuild"
    desc = "rebuild megamerge (no fetch)"
    lua = ''''
    exec_shell("JJ_MEGAMERGE_FETCH=0 jj-megamerge-rebuild")
    ''''
    key = "m"
    scope = "revisions"

    [[actions]]
    name = "megamerge-fetch-rebuild"
    desc = "fetch + rebuild megamerge"
    lua = ''''
    exec_shell("jj-megamerge-rebuild")
    ''''
    key = "F"
    scope = "revisions"
  '';
}
