{
  pkgs,
  lib,
  sources,
  ...
}:
let
  difit = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "difit";
    inherit (sources.difit) version src;

    nativeBuildInputs = with pkgs; [
      nodejs
      pnpm
      pnpmConfigHook
      makeWrapper
    ];

    pnpmDeps = pkgs.fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      fetcherVersion = 3;
      hash = "sha256-4qRRkIC1dZjSgLx+MR5QgEQstC/Z6GuKLLzZVn335zw=";
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
