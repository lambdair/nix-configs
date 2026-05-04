{ pkgs, sources, ... }:

let
  contents = pkgs.appimageTools.extractType2 {
    pname = "tolaria";
    inherit (sources.tolaria) version src;
  };
  tolaria = pkgs.appimageTools.wrapType2 {
    pname = "tolaria";
    inherit (sources.tolaria) version src;
    extraInstallCommands = ''
      install -m 444 -D ${contents}/Tolaria.desktop $out/share/applications/tolaria.desktop
      install -m 444 -D ${contents}/usr/share/icons/hicolor/128x128/apps/tolaria.png $out/share/icons/hicolor/128x128/apps/tolaria.png
      install -m 444 -D ${contents}/usr/share/icons/hicolor/256x256@2/apps/tolaria.png $out/share/icons/hicolor/256x256@2/apps/tolaria.png
      install -m 444 -D ${contents}/usr/share/icons/hicolor/32x32/apps/tolaria.png $out/share/icons/hicolor/32x32/apps/tolaria.png
    '';
  };
in
{
  home.packages = [ tolaria ];
}
