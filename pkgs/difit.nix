{ pkgs, sources }:
let
  # pnpm 12 is a Rust rewrite whose store layout fetchPnpmDeps cannot post-process,
  # so stay on the Node-based pnpm 11. Node 24's libuv aborts with a kqueue
  # assertion (kqueue.c:279) when pnpm uses its worker thread pool on macOS, hence
  # nodejs_22 LTS for pnpm and for the pnpm used internally by fetchPnpmDeps.
  pnpm = pkgs.pnpm_11.override { nodejs-slim = pkgs.nodejs_22; };
  fetchPnpmDeps = pkgs.fetchPnpmDeps.override { inherit pnpm; };
in
pkgs.stdenv.mkDerivation (finalAttrs: {
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
    fetcherVersion = 4;
    hash = "sha256-PLV82tBaOX7hDxRcV2owulK4EslaEcJGM1N1uuEQei8=";
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
    makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/difit \
      --add-flags "$out/lib/difit/dist/cli/index.js"
    runHook postInstall
  '';
})
