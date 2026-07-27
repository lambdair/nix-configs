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
      pname = "heptabase";
      source = sources.heptabase;
      desktop = "project-meta.desktop";
      icons = [
        {
          from = "usr/share/icons/hicolor/0x0/apps/project-meta.png";
          to = "hicolor/512x512/apps/heptabase.png";
        }
      ];
      extraInstall = ''
        substituteInPlace $out/share/applications/heptabase.desktop \
          --replace-fail 'Exec=AppRun' 'Exec=heptabase'
      '';
    })
  ];
}
