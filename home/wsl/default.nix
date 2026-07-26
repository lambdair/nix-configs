{ pkgs, ... }:

# Platform module for WSL: the counterpart to ./home/linux for an environment
# with no desktop session, so without the GUI apps and Wayland session tools.

rec {
  home.username = "lambdair";
  home.homeDirectory = "/home/${home.username}";

  home.packages = with pkgs; [
    wl-clipboard # Clipboard (shared with Windows through WSLg)
  ];
}
