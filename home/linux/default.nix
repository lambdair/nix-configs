{ pkgs, ... }:

rec {
  imports = [
    ./heptabase.nix
    ./tolaria.nix
    ./zmk-battery-center.nix
  ];

  home.username = "lambdair";
  home.homeDirectory = "/home/${home.username}";

  home.packages = with pkgs; [
    vivaldi
    nyxt
    thunderbird
    discord
    obsidian # Knowledge base
    bitwarden-desktop # pinned in overlays/pin-broken-pkg.nix
    obs-studio # Free and open source streaming/recording software
    (symlinkJoin {
      name = "peek";
      paths = [ peek ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/peek --set DISPLAY :0
      '';
    }) # Simple animated GIF screen recorder
    pcloud # Secure cloud storage client

    # Wayland desktop tools
    waybar # Status bar
    mako # Notification daemon
    swaylock # Screen lock
    swayidle # Idle management
    grim # Screenshots
    slurp # Region selection
    wl-clipboard # Clipboard (wl-copy/wl-paste)
    swaybg # Wallpaper
    vicinae # Raycast-compatible launcher
  ];

  xdg.configFile."niri/config.kdl".source = ./niri-config.kdl;
}
