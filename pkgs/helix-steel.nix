# Heavy build products of the helix-steel toolchain: the editor itself, the
# steel interpreter (for its cogs), the runtime with grammars, and the sulafat
# nREPL plugin. The user-facing wrapper lives in home/helix-steel.nix; it needs
# the home directory, which packages must not depend on.
{ pkgs, sources }:
let
  steelCoreHashForHelix = "sha256-rfifl52OXqL821l/aJBVbOXO90iPZG0UvjHJxaAIaEI=";
  steelCoreHashForSulafat = "sha256-vR2izfAXC0oidNtyIzdge04BV6C36wrg1qDDzEKAPeg=";

  grammarExt = if pkgs.stdenv.isDarwin then "dylib" else "so";

  # Grammars from helix-steel's own languages.toml pins, kept in lockstep with its
  # runtime queries (a revision skew silently breaks highlighting). grammars.nix
  # emits the platform-correct extension (.dylib on macOS, .so on Linux).
  helix-steel-grammars = pkgs.callPackage "${sources.helix-steel.src}/grammars.nix" {
    # proverif: its grammar moved from Codeberg to GitHub, and the Codeberg URL
    # languages.toml pins now answers 504/401, so fetching that revision fails.
    # Removable once languages.toml points at the new location.
    #
    # rpmspec and wikitext: their repositories carry paths differing only in
    # case. On a case-insensitive filesystem Lix drops one side of each
    # collision while Nix keeps both, so the two disagree on this derivation's
    # hash and a Lix host stops substituting the CI-built runtime. Removable
    # once Lix keeps such trees the way Nix does.
    includeGrammarIf =
      grammar:
      !(builtins.elem grammar.name [
        "proverif"
        "rpmspec"
        "wikitext"
      ]);
  };

  # helix-steel's fork predates upstream moonbit support, so its languages.toml
  # has neither grammar nor queries. Build the moonbit grammar from upstream
  # helix's grammars.nix, which pins the tree-sitter revision its queries expect;
  # taking both from one pin keeps them in lockstep (a skew silently breaks
  # highlighting).
  helix-moonbit-grammars = pkgs.callPackage "${sources.helix-mainline.src}/grammars.nix" {
    includeGrammarIf = grammar: grammar.name == "moonbit";
  };

  # MoonBit's proof files (`.mbtp`) parse with a subgrammar of
  # tree-sitter-moonbit. Its queries sit beside it in the same tree, so the one
  # pin keeps grammar and queries in lockstep.
  moonbit-mbtp-grammar = pkgs.tree-sitter.buildGrammar {
    language = "moonbit-mbtp";
    inherit (sources.tree-sitter-moonbit) version src;
    location = "grammars/mbtp";
  };
in
rec {
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
        "steel-core-0.8.3" = steelCoreHashForHelix;
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
    # moonbit-mbtp grammar + queries from tree-sitter-moonbit
    mkdir -p $out/queries/moonbit-mbtp
    cp -r ${sources.tree-sitter-moonbit.src}/grammars/mbtp/queries/* $out/queries/moonbit-mbtp/
    ln -s ${moonbit-mbtp-grammar}/parser $out/grammars/moonbit-mbtp.${grammarExt}
  '';

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
}
