{ pkgs, sources, ... }:

let
  zmk-battery-center = pkgs.stdenv.mkDerivation {
    pname = "zmk-battery-center";
    inherit (sources.zmk-battery-center-mac) version src;

    sourceRoot = ".";

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/Applications
      cp -R *.app $out/Applications/
      runHook postInstall
    '';
  };
in
{
  home.packages = [ zmk-battery-center ];
}
