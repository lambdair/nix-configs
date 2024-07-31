{ config, pkgs, ... }:

rec {
  home.username = "lambdair";
  home.homeDirectory = "/home/${home.username}";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # language
    uiua
    tree-sitter-grammars.tree-sitter-uiua
    nil
    nixfmt-rfc-style
    rust-bin.stable.latest.default
    rust-analyzer

    # cui tools
    ripgrep
    fd
    tldr

    # gui tools
    emacs-unstable
    vivaldi
    thunderbird
    (pkgs.appimageTools.wrapType2 {
      name = "heptabase";
      version = "1.34.0";
      src = fetchurl {
        url = "https://github.com/heptameta/project-meta/releases/download/v1.34.0/Heptabase-1.34.0.AppImage";
        sha256 = "0lbmyb3wr4jj0w47b3zdxlrnq8dyb5yjqzr4lmqqrhvxbabs037b";
      };
    })
  ];

  imports = [ ./helix.nix ];

  catppuccin = {
    flavor = "frappe";
    enable = true;
  };

  programs = {
    wezterm = {
      enable = true;
      extraConfig = builtins.readFile ./wezterm.lua;
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
      };
      environmentVariables = {
        EDITOR = "hx";
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
    };

    ncspot = {
      enable = true;
      settings = {
        use_nerdfont = true;
      };
    };
  };
}
