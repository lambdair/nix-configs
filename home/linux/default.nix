{ pkgs, sources, ... }:

let
  heptabase = pkgs.appimageTools.wrapType2 {
    pname = "heptabase";
    version = sources.heptabase.version;
    src = sources.heptabase.src;
  };
in
rec {
  home.username = "lambdair";
  home.homeDirectory = "/home/${home.username}";

  home.packages = with pkgs; [
    vivaldi
    nyxt
    thunderbird
    discord
    heptabase
  ];
}
