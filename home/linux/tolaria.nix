{
  pkgs,
  lib,
  sources,
  ...
}:

let
  mkAppImage = import ./appimage.nix { inherit pkgs lib; };
  icon = size: {
    from = "usr/share/icons/hicolor/${size}/apps/tolaria.png";
    to = "hicolor/${size}/apps/tolaria.png";
  };
in
{
  home.packages = [
    (mkAppImage {
      pname = "tolaria";
      source = sources.tolaria;
      desktop = "Tolaria.desktop";
      icons = map icon [
        "128x128"
        "256x256@2"
        "32x32"
      ];
    })
  ];
}
