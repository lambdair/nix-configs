{
  pkgs,
  sources,
  ...
}:
let
  steelCoreHash = "sha256-xHd82gFsfafOm/zkusiZ6tdd+gOfKkgzyk4EFQ9eNIs=";

  steel = pkgs.rustPlatform.buildRustPackage {
    pname = "steel";
    inherit (sources.steel) version src;
    cargoLock.lockFile = "${sources.steel.src}/Cargo.lock";

    # Tests require cogs at ~/.local/share/steel/ which is unavailable in sandbox
    doCheck = false;

    postInstall = ''
      mkdir -p $out/lib/steel
      cp -r cogs $out/lib/steel/
    '';
  };

  helix-steel-unwrapped = pkgs.rustPlatform.buildRustPackage {
    pname = "helix-steel";
    inherit (sources.helix-steel) version src;
    cargoLock = {
      lockFile = "${sources.helix-steel.src}/Cargo.lock";
      outputHashes = {
        "steel-core-0.8.2" = steelCoreHash;
      };
    };

    buildFeatures = [
      "steel"
      "git"
    ];

    nativeBuildInputs = [ pkgs.git ];

    env.HELIX_DISABLE_AUTO_GRAMMAR_BUILD = "1";

    postInstall = ''
      mkdir -p $out/lib/helix
      cp -r runtime $out/lib/helix/runtime
    '';
  };

  helix-steel = pkgs.symlinkJoin {
    name = "helix-steel";
    paths = [ helix-steel-unwrapped ];
    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
    postBuild = ''
      rm $out/bin/hx
      makeBinaryWrapper ${helix-steel-unwrapped}/bin/hx $out/bin/hx \
        --set HELIX_RUNTIME "${helix-steel-unwrapped}/lib/helix/runtime" \
        --set STEEL_HOME "${steel}/lib/steel"
    '';
  };
in
{
  programs.helix.package = helix-steel;
}
