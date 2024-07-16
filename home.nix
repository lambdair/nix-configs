{ config, pkgs, ... }:

rec {
  home.username = "lambdair";
  home.homeDirectory = "/home/${home.username}";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
  ];

  programs = {
    wezterm = {
      enable = true;
      extraConfig = builtins.readFile ./wezterm.lua;
    };

    git = {
      enable = true;
      userEmail = "lambdair1984@protonmail.com";
      userName = "Lambdair";
    };

    jujutsu = {
      enable = true;
      settings = {
        user.email = "lambdair1984@protonmail.com";
        user.name = "Lambdair";
      };
    };
  };
}
