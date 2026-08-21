# druk: terminal code editor shipped as one self-contained binary. Not in
# nixpkgs, and building it from source means running a Bun install and
# `bun build --compile`, so the upstream release archive is repackaged per
# platform.
{ pkgs, sources }:

let
  inherit (pkgs) lib stdenv;
  source = if stdenv.isDarwin then sources.druk-mac else sources.druk-linux;
in
stdenv.mkDerivation {
  pname = "druk";
  inherit (source) version src;

  # The archive holds the executable and its license notices at the top level.
  sourceRoot = ".";

  # The Linux binary links against glibc at fixed paths; unzip reads the macOS
  # archive, which is a zip rather than a tarball.
  nativeBuildInputs =
    lib.optional stdenv.isDarwin pkgs.unzip ++ lib.optional stdenv.isLinux pkgs.autoPatchelfHook;

  dontConfigure = true;
  dontBuild = true;

  # The application is a payload embedded in a prebuilt Bun runtime: stripping
  # drops it, leaving a bare `bun`, and on macOS also invalidates the
  # linker-signed ad-hoc signature.
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 druk $out/bin/druk
    install -Dm644 -t $out/share/doc/druk THIRD_PARTY_NOTICES.md PDFIUM_LICENSE
    runHook postInstall
  '';

  meta = {
    description = "Terminal code editor with tree-sitter syntax, LSP and git";
    homepage = "https://github.com/letstri/druk";
    license = lib.licenses.mit;
    mainProgram = "druk";
    platforms = [
      "aarch64-darwin"
      "x86_64-linux"
    ];
  };
}
