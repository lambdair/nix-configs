{ pkgs, sources, ... }:

let
  contents = pkgs.appimageTools.extractType2 {
    pname = "zmk-battery-center";
    inherit (sources.zmk-battery-center-linux) version src;
  };
  zmk-battery-center = pkgs.appimageTools.wrapType2 {
    pname = "zmk-battery-center";
    inherit (sources.zmk-battery-center-linux) version src;
    extraInstallCommands = ''
      install -m 444 -D ${contents}/zmk-battery-center.desktop \
        $out/share/applications/zmk-battery-center.desktop
      install -m 444 -D ${contents}/usr/share/icons/hicolor/256x256@2/apps/zmk-battery-center.png \
        $out/share/icons/hicolor/256x256@2/apps/zmk-battery-center.png
    '';
  };
in
{
  home.packages = [ zmk-battery-center ];
}
