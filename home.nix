{ config, pkgs, ... }:

rec {
  home.username = "lambdair";
  home.homeDirectory = "/home/${home.username}";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
  ];

  programs = {
  };
}
