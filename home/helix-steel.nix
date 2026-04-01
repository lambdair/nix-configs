{
  pkgs,
  config,
  sources,
  ...
}:
let
  steelCoreHashForHelix = "sha256-DX8QDtA1jsYJzLLQ06E9nQIFkwXVNbBL/SLAYeNiJvg=";
  steelCoreHashForSulafat = "sha256-xHd82gFsfafOm/zkusiZ6tdd+gOfKkgzyk4EFQ9eNIs=";

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
        "steel-core-0.8.2" = steelCoreHashForHelix;
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

  grammarExt = if pkgs.stdenv.isDarwin then "dylib" else "so";

  helix-runtime = pkgs.runCommand "helix-steel-runtime" { } ''
    mkdir -p $out
    cp -r --no-preserve=mode ${helix-steel-unwrapped}/lib/helix/runtime/* $out/
    # nixpkgs pre-compiled grammars (writable dir for uiua addition)
    rm -rf $out/grammars
    mkdir -p $out/grammars
    cp -r --no-preserve=mode ${pkgs.helix.passthru.runtime}/grammars/* $out/grammars/
    # helix master expects .dylib on macOS, but nixpkgs grammars are .so
    ${pkgs.lib.optionalString pkgs.stdenv.isDarwin ''
      for f in $out/grammars/*.so; do
        mv "$f" "''${f%.so}.dylib"
      done
    ''}
    # uiua tree-sitter grammar (not in nixpkgs helix runtime)
    mkdir -p $out/queries/uiua
    cp -r ${pkgs.tree-sitter-grammars.tree-sitter-uiua}/queries/* $out/queries/uiua/
    ln -s ${pkgs.tree-sitter-grammars.tree-sitter-uiua}/parser $out/grammars/uiua.${grammarExt}
  '';

  helix-steel = pkgs.symlinkJoin {
    name = "helix-steel";
    paths = [ helix-steel-unwrapped ];
    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
    postBuild = ''
      rm $out/bin/hx
      makeBinaryWrapper ${helix-steel-unwrapped}/bin/hx $out/bin/hx \
        --set HELIX_RUNTIME "${helix-runtime}" \
        --set STEEL_HOME "${config.home.homeDirectory}/.steel"
    '';
  };

  sulafat = pkgs.rustPlatform.buildRustPackage {
    pname = "sulafat";
    inherit (sources.sulafat) version src;
    cargoLock = {
      lockFile = "${sources.sulafat.src}/Cargo.lock";
      outputHashes = {
        "steel-core-0.8.2" = steelCoreHashForSulafat;
      };
    };

    buildAndTestSubdir = "crates/steel-nrepl";
  };

  nreplLibName = if pkgs.stdenv.isDarwin then "libsteel_nrepl.dylib" else "libsteel_nrepl.so";
in
{
  programs.helix.package = helix-steel;

  home.file.".steel/cogs" = {
    source = "${steel}/lib/steel/cogs";
    recursive = true;
  };

  home.file.".steel/native/${nreplLibName}".source = sulafat + "/lib/${nreplLibName}";

  home.file.".config/helix/nrepl.scm".source = "${sources.sulafat.src}/nrepl.scm";

  home.file.".config/helix/cogs/nrepl" = {
    source = "${sources.sulafat.src}/cogs/nrepl";
    recursive = true;
  };

  home.file.".config/helix/init.scm".text = ''
    (require (prefix-in helix. "helix/commands.scm"))
    (require (prefix-in helix.static. "helix/static.scm"))
    (require "helix/keymaps.scm")
    (require "nrepl.scm")

    (keymap (global)
            (normal (space (n (C ":nrepl-connect")
                              (D ":nrepl-disconnect")
                              (J ":nrepl-jack-in")
                              (L ":nrepl-load-file")
                              (b ":nrepl-eval-buffer")
                              (l ":nrepl-lookup")
                              (m ":nrepl-eval-multiple-selections")
                              (p ":nrepl-eval-prompt")
                              (s ":nrepl-eval-selection")))
                    (A-ret ":nrepl-eval-selection"))
            (select (space (n (C ":nrepl-connect")
                              (D ":nrepl-disconnect")
                              (J ":nrepl-jack-in")
                              (L ":nrepl-load-file")
                              (b ":nrepl-eval-buffer")
                              (l ":nrepl-lookup")
                              (m ":nrepl-eval-multiple-selections")
                              (p ":nrepl-eval-prompt")
                              (s ":nrepl-eval-selection")))
                    (A-ret ":nrepl-eval-selection")))
  '';
}
