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
      version = "1.34.0";
      src = fetchurl {
        url = "https://github.com/heptameta/project-meta/releases/download/v1.34.0/Heptabase-1.34.0.AppImage";
        sha256 = "0lbmyb3wr4jj0w47b3zdxlrnq8dyb5yjqzr4lmqqrhvxbabs037b";
      };
    })
  ];
}
