{
  pkgs,
  lib,
  sources,
  inputs,
  ...
}:
let
  libs = with pkgs; [
    SDL2
    SDL2_ttf
    SDL2_image
    libffi
    openssl
    ncurses
  ];
  libPath = lib.makeLibraryPath libs;

  budget_tracker_tui = pkgs.rustPlatform.buildRustPackage {
    inherit (sources.budget_tracker_tui) pname version src;
    cargoLock.lockFile = "${sources.budget_tracker_tui.src}/Cargo.lock";
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
      volta # JavaScript tool manager
      nodePackages.typescript-language-server # TypeScript/JavaScript language server
      tailwindcss-language-server # Tailwind CSS language server

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Rust Development
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      rust-bin.stable.latest.default # Rust toolchain (stable)
      rust-analyzer # Modular compiler frontend for the Rust language

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Theorem Proving / Formal Verification
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      lean4 # Automatic and interactive theorem prover
      # isabelle
      maude # High-level specification language
      # teyjus # Efficient implementation of Lambda Prolog
      abella # Interactive theorem prover

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Lisp / Scheme
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # sbcl
      # racket
      # racket-minimal
      guile # Embeddable Scheme implementation

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Clojure / Fennel
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # clojure
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
      television # Fuzzy finder TUI
      ripgrep # Fast grep alternative (rg)
      fd # Simple, fast alternative to find
      superfile # Pretty fancy and modern terminal file manager
      dust # du + rust = dust. More intuitive disk usage

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Git / Version Control
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # gitu # TUI Git client inspired by Magit
      tig # Text-mode interface for git
      lazyjj # TUI for Jujutsu/jj
      jjui # TUI for Jujutsu
      gh-dash # GitHub CLI extension for PR/issue dashboard

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Development Tools
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      tldr # Simplified and community-driven man pages
      emacs-lsp-booster # Emacs LSP performance booster
      parinfer-rust-emacs # Emacs centric fork of parinfer-rust
      d2 # Modern diagram scripting language
      typos-lsp # Source code spell checker
      zoekt # Fast trigram based code search
      graphviz # Graph visualization tools
      go-migrate # Database migrations
      jq # Command-line JSON processor
      ansifilter # ANSI escape code filter
      python312Packages.pylatexenc # LaTeX encoder for Python
      # python313Packages.uv

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
      mcat # Media file metadata viewer
      alda # Music programming language

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Web / Mail / HTTP
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      posting # HTTP client TUI
      himalaya # CLI to manage emails
      w3m # Text-mode web browser
      chawan # Lightweight terminal web browser
      ngrok # Secure tunnels to localhost

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Notes / Knowledge Management
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      nb # Command line note-taking and knowledge base
      rucola # Terminal-based markdown note manager
      tdf # TUI-based PDF viewer
      glow # Render markdown on the CLI
      sdcv # StarDict console version
      dict # Dictionary client
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
      basalt # Bash package manager
      pik # Process interactive kill
      xan # CSV toolkit
      tuios # Network TUI for Unix sockets
      enchant # Generic spell checking library
      github-cli # GitHub CLI
      claude-code # Agentic coding tool
      codex # OpenAI Codex CLI

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # GUI Applications
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # ghostty
      warp-terminal # Modern terminal with AI features
      rio # Hardware-accelerated GPU terminal emulator
      obsidian # Knowledge base

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Fonts
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      nerd-fonts.hack
      nerd-fonts.sauce-code-pro
      julia-mono
      rounded-mgenplus
      uiua386
      apl386
      bqn386
    ]
    ++ libs;

  imports = [
    ./helix.nix
    ./nvim
    ./emacs
  ];

  catppuccin = {
    flavor = "frappe";
    enable = true;
    nvim.enable = false;
  };

  programs = {
    wezterm = {
      enable = true;
      extraConfig = builtins.readFile ./wezterm.lua;
    };

    kitty = {
      enable = true;
      extraConfig = builtins.readFile ./kitty.conf;
    };

    git = {
      enable = true;
      settings = {
        user.email = "lambdair1984@protonmail.com";
        user.name = "Lambdair";
      };
    };

    delta = {
      enable = true;
      enableGitIntegration = true;
    };

    jujutsu = {
      enable = true;
      settings = {
        user.email = "lambdair1984@protonmail.com";
        user.name = "Lambdair";
      };
    };

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
        nrepl = "clj -Sdeps '{:deps {cider/cider-nrepl {:mvn/version \"0.52.0\"} }}' -m nrepl.cmdline --middleware \"[cider.nrepl/cider-middleware]\"";
      };
      environmentVariables = {
        EDITOR = "hx";
        LD_LIBRARY_PATH = "'${libPath}'";
      };
      configFile.source = ./config.nu;
    };

    carapace.enable = true;
    carapace.enableNushellIntegration = true;

    starship = {
      enable = true;
    };

    zoxide = {
      enable = true;
      enableNushellIntegration = true;
    };

    zellij = {
      enable = true;
    };

    bat = {
      enable = true;
    };

    fzf = {
      enable = true;
    };

    yazi = {
      enable = true;
    };

    lazygit = {
      enable = true;
      settings = {
        os.editPreset = "nvim";
      };
    };

    ncspot = {
      enable = true;
      settings = {
        use_nerdfont = true;
      };
    };
  };

  home.file.".config/helix/runtime/queries/uiua" = {
    source = "${pkgs.tree-sitter-grammars.tree-sitter-uiua}/queries";
    recursive = true;
  };
  home.file.".config/helix/runtime/grammars/uiua.so" = {
    source = "${pkgs.tree-sitter-grammars.tree-sitter-uiua}/parser";
  };
}
