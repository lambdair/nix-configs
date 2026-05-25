{
  pkgs,
  lib,
  sources,
  ...
}:
let
  # Node 24's libuv aborts with a kqueue assertion (kqueue.c:279) when pnpm uses
  # its worker thread pool on macOS. Pin pnpm (and the pnpm used internally by
  # fetchPnpmDeps) to nodejs_22 LTS as a workaround.
  pnpm = pkgs.pnpm.override { nodejs = pkgs.nodejs_22; };
  fetchPnpmDeps = pkgs.fetchPnpmDeps.override { inherit pnpm; };

  difit = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "difit";
    inherit (sources.difit) version src;

    nativeBuildInputs = [
      pkgs.nodejs_22
      pnpm
      pkgs.pnpmConfigHook
      pkgs.makeWrapper
    ];

    pnpmDeps = fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      fetcherVersion = 3;
      hash = "sha256-JtSqmcT5Kan/12lC8DbfBkVStOz8Ra2UTMyHiwMDphY=";
    };

    buildPhase = ''
      runHook preBuild
      pnpm build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/difit $out/bin
      cp -r dist node_modules package.json $out/lib/difit/
      # Remove broken workspace symlinks (e.g. vscode extension)
      find $out/lib/difit/node_modules -xtype l -delete
      makeWrapper ${pkgs.nodejs}/bin/node $out/bin/difit \
        --add-flags "$out/lib/difit/dist/cli/index.js"
      runHook postInstall
    '';
  });
in
{
  home.packages = [ difit ];
}
