{ pkgs, sources, ... }:

let
  heptabaseContents = pkgs.appimageTools.extractType2 {
    pname = "heptabase";
    inherit (sources.heptabase) version src;
  };
  heptabase = pkgs.appimageTools.wrapType2 {
    pname = "heptabase";
    inherit (sources.heptabase) version src;
    extraInstallCommands = ''
      install -m 444 -D ${heptabaseContents}/project-meta.desktop $out/share/applications/heptabase.desktop
      install -m 444 -D ${heptabaseContents}/usr/share/icons/hicolor/0x0/apps/project-meta.png $out/share/icons/hicolor/512x512/apps/heptabase.png
      substituteInPlace $out/share/applications/heptabase.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=heptabase'
    '';
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
