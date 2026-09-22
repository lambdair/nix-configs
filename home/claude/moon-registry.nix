# Offline mooncakes registry shared by the MoonBit packages under this
# directory (statusline, hepta-lint).
#
# MoonBit is not in nixpkgs; the toolchain comes from the moonbit-overlay input
# (pkgs.moonbit-bin.moonbit.latest). Package builds must not touch the network,
# so the deps are fetched here — in a fixed-output derivation, the only step
# allowed network access — and served to the builds through MOON_HOME.
#
# The output is deterministic: the version-pinned zips (content-addressed,
# stable) plus a single index line each (that version's metadata never
# changes). The full 18M index git clone is intentionally dropped so the output
# hash is stable.
#
# Bump outputHash whenever the versions below or the moon toolchain change
# (nix prints the new hash on mismatch).
{ pkgs }:
let
  moon = pkgs.moonbit-bin.moonbit.latest;

  asyncVersion = "0.20.6";
  xVersion = "0.5.1";

  # Manifest listing the exact deps to fetch. Kept in sync with the moon.mod of
  # every package that uses this registry. The module name is part of what
  # `moon install` writes, so it stays as it was when outputHash was taken.
  depsMod = pkgs.writeText "deps-moon.mod" ''
    name = "vendor/statusline-deps"
    version = "0.0.0"
    import {
      "moonbitlang/async@${asyncVersion}",
      "moonbitlang/x@${xVersion}",
    }
  '';
in
pkgs.stdenv.mkDerivation {
  name = "claude-moon-registry";
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
  outputHash = "sha256-QvGxtKOAGD4oc8EP/88madZvki57d/wgyTmfxVOtnq0=";
}
