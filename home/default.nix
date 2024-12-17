{ pkgs, lib, ... }:
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
rec {
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  home.packages =
    with pkgs;
    [
      # language
      uiua
      tree-sitter-grammars.tree-sitter-uiua
      nil
      nixfmt-rfc-style
      rust-bin.stable.latest.default
      rust-analyzer
      (pkgs.callPackage ./lean4.nix {
        inherit (pkgs) fetchFromGitHub;
      })
      isabelle
      maude
      sbcl
      racket-minimal
      guile
      clojure
      clojure-lsp
      cljfmt
      babashka
      scryer-prolog

      # cui tools
      ripgrep
      fd
      tldr
      tdf
      nb
      nix-search
      python312Packages.pylatexenc

      # gui tools
      emacs-git
    ]
    ++ libs;

  imports = [
    ./helix.nix
    ./nvim
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
      };
      environmentVariables = {
        EDITOR = "'emacsclient -nw -a nvim'";
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
}
