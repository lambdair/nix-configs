{ pkgs, sources, ... }:

let
  contents = pkgs.appimageTools.extractType2 {
    pname = "heptabase";
    inherit (sources.heptabase) version src;
  };
  heptabase = pkgs.appimageTools.wrapType2 {
    pname = "heptabase";
    inherit (sources.heptabase) version src;
    extraInstallCommands = ''
      install -m 444 -D ${contents}/project-meta.desktop $out/share/applications/heptabase.desktop
      install -m 444 -D ${contents}/usr/share/icons/hicolor/0x0/apps/project-meta.png $out/share/icons/hicolor/512x512/apps/heptabase.png
      substituteInPlace $out/share/applications/heptabase.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=heptabase'
    '';
  };
in
{
  home.packages = [ heptabase ];
}
