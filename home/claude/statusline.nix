# Claude Code statusline: a MoonBit program built to a native binary.
#
# MoonBit is not in nixpkgs; the toolchain comes from the moonbit-overlay input
# (pkgs.moonbit-bin.moonbit.latest). The deps come from the shared offline
# registry in ./moon-registry.nix, served to the build via MOON_HOME.
{ pkgs }:
let
  moon = pkgs.moonbit-bin.moonbit.latest;
  moonRegistry = import ./moon-registry.nix { inherit pkgs; };
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
