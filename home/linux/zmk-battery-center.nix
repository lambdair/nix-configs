{
  pkgs,
  lib,
  sources,
  ...
}:

let
  mkAppImage = import ./appimage.nix { inherit pkgs lib; };
in
{
  home.packages = [
    (mkAppImage {
      pname = "zmk-battery-center";
      source = sources.zmk-battery-center-linux;
      desktop = "zmk-battery-center.desktop";
      icons = [
        {
          from = "usr/share/icons/hicolor/256x256@2/apps/zmk-battery-center.png";
          to = "hicolor/256x256@2/apps/zmk-battery-center.png";
        }
      ];
    })
  ];
}
