# Claude Code statusline: a MoonBit program built to a native binary.
#
# MoonBit is not in nixpkgs; the toolchain comes from the moonbit-overlay input
# (pkgs.moonbit-bin.moonbit.latest). The two deps (moonbitlang/async + /x) are
# fetched by `moonRegistry` below — a fixed-output derivation — and served to
# the offline package build via MOON_HOME.
{ pkgs }:
let
  moon = pkgs.moonbit-bin.moonbit.latest;

  asyncVersion = "0.20.3";
  xVersion = "0.4.47";

  # Manifest listing the exact deps to fetch. Kept in sync with
  # ./statusline/moon.mod.
  depsMod = pkgs.writeText "deps-moon.mod" ''
    name = "vendor/statusline-deps"
    version = "0.0.0"
    import {
      "moonbitlang/async@${asyncVersion}",
      "moonbitlang/x@${xVersion}",
    }
  '';

  # Fixed-output derivation: the only step allowed network access. It fetches
  # the pinned deps from the mooncakes registry and emits a deterministic
  # offline registry — the version-pinned zips (content-addressed, stable) plus
  # a single index line each (that version's metadata never changes). The full
  # 18M index git clone is intentionally dropped so the output hash is stable.
  #
  # Bump outputHash whenever asyncVersion/xVersion change (nix prints the new
  # hash on mismatch).
  moonRegistry = pkgs.stdenv.mkDerivation {
    name = "claude-statusline-moon-registry";
    dontUnpack = true;
    nativeBuildInputs = [
      moon
      pkgs.git
      pkgs.cacert
    ];
    buildPhase = ''
      export HOME="$TMPDIR"
      export MOON_HOME="$TMPDIR/moon-home"
      export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      export GIT_SSL_CAINFO="$SSL_CERT_FILE"
      mkdir -p "$MOON_HOME" proj
      cp ${depsMod} proj/moon.mod
      cd proj
      moon update      # clone the registry index
      moon install     # download the pinned dep zips
    '';
    installPhase = ''
      idx="$MOON_HOME/registry/index/user/moonbitlang"
      mkdir -p "$out/registry/cache" "$out/registry/index/user/moonbitlang"
      cp -r "$MOON_HOME/registry/cache/moonbitlang" "$out/registry/cache/"
      grep '"version": "${asyncVersion}"' "$idx/async.index" \
        > "$out/registry/index/user/moonbitlang/async.index"
      grep '"version": "${xVersion}"' "$idx/x.index" \
        > "$out/registry/index/user/moonbitlang/x.index"
    '';
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-AzMMjR5vdM3IgwaPUKfaSSglpOjvfXZAI0jleg8XZ4I=";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "claude-statusline";
  version = "0.1.0";
  src = ./statusline;

  nativeBuildInputs = [ moon ];

  # The native backend emits C and links it, so a C compiler is required;
  # stdenv provides one. moonbit.h ships inside the toolchain.
  buildPhase = ''
    runHook preBuild

    # Seed MOON_HOME with the pre-fetched registry so the build stays offline.
    export HOME="$TMPDIR"
    export MOON_HOME="$TMPDIR/moon-home"
    mkdir -p "$MOON_HOME"
    cp -R --no-preserve=mode,ownership "${moonRegistry}/registry" "$MOON_HOME/registry"

    moon build cmd/main --target native --release

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 \
      _build/native/release/build/cmd/main/main.exe \
      "$out/bin/claude-statusline"
    runHook postInstall
  '';

  # Tests run in the dev checkout (moon test); keep the package build lean.
  doCheck = false;
}
