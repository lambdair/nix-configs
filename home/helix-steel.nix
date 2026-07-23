{
  pkgs,
  config,
  sources,
  ...
}:
let
  steelCoreHashForHelix = "sha256-vR2izfAXC0oidNtyIzdge04BV6C36wrg1qDDzEKAPeg=";
  steelCoreHashForSulafat = "sha256-vR2izfAXC0oidNtyIzdge04BV6C36wrg1qDDzEKAPeg=";

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

  # Grammars from helix-steel's own languages.toml pins, kept in lockstep with its
  # runtime queries (a revision skew silently breaks highlighting). grammars.nix
  # emits the platform-correct extension (.dylib on macOS, .so on Linux).
  helix-steel-grammars = pkgs.callPackage "${sources.helix-steel.src}/grammars.nix" { };

  # helix-steel's fork predates upstream moonbit support, so its languages.toml
  # has neither grammar nor queries. Build the moonbit grammar from upstream
  # helix's grammars.nix, which pins the tree-sitter revision its queries expect;
  # taking both from one pin keeps them in lockstep (a skew silently breaks
  # highlighting).
  helix-moonbit-grammars = pkgs.callPackage "${sources.helix-mainline.src}/grammars.nix" {
    includeGrammarIf = grammar: grammar.name == "moonbit";
  };

  helix-runtime = pkgs.runCommand "helix-steel-runtime" { } ''
    mkdir -p $out
    cp -r --no-preserve=mode ${helix-steel-unwrapped}/lib/helix/runtime/* $out/
    # grammars built from helix-steel's pins (writable dir for uiua addition)
    rm -rf $out/grammars
    mkdir -p $out/grammars
    cp -rL --no-preserve=mode ${helix-steel-grammars}/* $out/grammars/
    # uiua tree-sitter grammar (not in helix-steel languages.toml)
    mkdir -p $out/queries/uiua
    cp -r ${pkgs.tree-sitter-grammars.tree-sitter-uiua}/queries/* $out/queries/uiua/
    ln -s ${pkgs.tree-sitter-grammars.tree-sitter-uiua}/parser $out/grammars/uiua.${grammarExt}
    # moonbit grammar + queries from upstream helix (not in helix-steel)
    mkdir -p $out/queries/moonbit
    cp -r ${sources.helix-mainline.src}/runtime/queries/moonbit/* $out/queries/moonbit/
    ln -s ${helix-moonbit-grammars}/moonbit.${grammarExt} $out/grammars/moonbit.${grammarExt}
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

  home.file.".config/helix/lean-unicode.hx/abbreviations.scm".source =
    "${sources.lean-unicode-hx.src}/abbreviations.scm";
  home.file.".config/helix/lean-unicode.hx/engine.scm".source =
    "${sources.lean-unicode-hx.src}/engine.scm";
  home.file.".config/helix/lean-unicode.hx/lean-unicode.scm".source =
    "${sources.lean-unicode-hx.src}/lean-unicode.scm";
  home.file.".config/helix/lean-unicode.hx/cog.scm".source = "${sources.lean-unicode-hx.src}/cog.scm";

  home.file.".config/helix/init.scm".text = ''
    (require (prefix-in helix. "helix/commands.scm"))
    (require (prefix-in helix.static. "helix/static.scm"))
    (require "helix/keymaps.scm")
    (require "nrepl.scm")
    (require "lean-unicode.hx/lean-unicode.scm")

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

    ;; Lean4 Unicode abbreviation: \ in insert mode on .lean files
    (keymap (extension "lean") (insert ("\\" enter-abbrev-mode)))
  '';
}
