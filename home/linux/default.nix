{ pkgs, ... }:

rec {
  home.username = "lambdair";
  home.homeDirectory = "/home/${home.username}";

  home.packages = with pkgs; [
    vivaldi
    nyxt
    thunderbird
    discord
    (pkgs.appimageTools.wrapType2 {
      name = "heptabase";
      version = "1.41.1";
      src = fetchurl {
        url = "https://github.com/heptameta/project-meta/releases/download/v1.41.1/Heptabase-1.41.1.AppImage";
        sha256 = "MX5lKTSJFBhtUMPlefSWvVayFYt0ydZ7lToUDdDUsT4=";
      };
    })
  ];
}
