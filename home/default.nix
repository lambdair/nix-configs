{ pkgs, lib, sources, ... }:
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
in
{
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  home.packages =
    with pkgs;
    [
      guix

      # language
      uiua
      tree-sitter-grammars.tree-sitter-uiua
      nil
      nixfmt-rfc-style
      rust-bin.stable.latest.default
      rust-analyzer
      lean4
      # isabelle
      maude
      sbcl
      racket
      guile
      clojure
      clojure-lsp
      cljfmt
      babashka
      fennel-ls
      fnlfmt
      scryer-prolog
      ciao
      teyjus
      abella
      typst
      typstyle
      tinymist

      # cui tools
      ripgrep
      fd
      tldr
      tdf
      nb
      nix-search
      nvfetcher
      python312Packages.pylatexenc
      emacs-lsp-booster
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
      userEmail = "lambdair1984@protonmail.com";
      userName = "Lambdair";

      delta = {
        enable = true;
      };
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
        et = "emacsclient -nw -a nvim";
        es = "emacs --daemon";
        ek = "emacsclient -e '(kill-emacs)'";
        vi = "nvim";
        uu = "uiua repl";
        nrepl = "clj -Sdeps '{:deps {cider/cider-nrepl {:mvn/version \"0.52.0\"} }}' -m nrepl.cmdline --middleware \"[cider.nrepl/cider-middleware]\"";
      };
      environmentVariables = {
        EDITOR = "nvim";
        LD_LIBRARY_PATH = "'${libPath}'";
      };
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
