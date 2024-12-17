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
      pname = "heptabase";
      version = "1.41.1";
      src = fetchurl {
        url = "https://github.com/heptameta/project-meta/releases/download/v1.43.0/Heptabase-1.43.0.AppImage";
        sha256 = "sha256-ig56Xyh6+UQerR+wXg0Sp4GLBosrUc07C/6B27TbAz8=";
      };
    })
  ];
}
