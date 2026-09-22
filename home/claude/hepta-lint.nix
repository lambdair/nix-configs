# hepta-lint: the concept-card format checker driven by the
# creating-heptabase-concept-card skill, built from the MoonBit sources that
# ship with the skill.
#
# Built to wasm and run through `moonrun` (part of the MoonBit toolchain), so
# the wrapper carries moonrun. The same sources build on Windows, where the
# skill builds them itself.
#
# The skill's moon.mod may only import versions ./moon-registry.nix carries —
# the build has no network. moon.mod takes no comments, so the constraint is
# recorded here: bumping the dep there means bumping the registry and its
# outputHash too.
{ pkgs }:
let
  moon = pkgs.moonbit-bin.moonbit.latest;
  moonRegistry = import ./moon-registry.nix { inherit pkgs; };
in
pkgs.stdenv.mkDerivation {
  pname = "hepta-lint";
  version = "0.1.0";
  src = ./skills/creating-heptabase-concept-card/scripts/hepta-lint;

  nativeBuildInputs = [
    moon
    pkgs.makeWrapper
  ];

  buildPhase = ''
    runHook preBuild

    # Seed MOON_HOME with the pre-fetched registry so the build stays offline.
    export HOME="$TMPDIR"
    export MOON_HOME="$TMPDIR/moon-home"
    mkdir -p "$MOON_HOME"
    cp -R --no-preserve=mode,ownership "${moonRegistry}/registry" "$MOON_HOME/registry"

    moon build cmd/main --target wasm --release

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm644 \
      _build/wasm/release/build/cmd/main/main.wasm \
      "$out/share/hepta-lint/hepta-lint.wasm"

    # The skill calls `hepta-lint <note.json> <props.json>`; moonrun needs the
    # wasm and `--` before the program's own arguments.
    makeWrapper ${moon}/bin/moonrun "$out/bin/hepta-lint" \
      --add-flags "$out/share/hepta-lint/hepta-lint.wasm --"

    runHook postInstall
  '';

  # Tests run in the dev checkout (moon test); keep the package build lean.
  doCheck = false;
}
