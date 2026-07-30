# lightpanda: headless browser built for agents, with a JS engine, a CDP server
# and a native MCP server. Not in nixpkgs, and building it from source means
# building its v8 fork, so the upstream release binary is repackaged per
# platform.
{ pkgs, sources }:

let
  inherit (pkgs) lib stdenv;
  source = if stdenv.isDarwin then sources.lightpanda-mac else sources.lightpanda-linux;
in
stdenv.mkDerivation {
  pname = "lightpanda";
  inherit (source) version src;

  # The release asset is the bare executable.
  dontUnpack = true;

  # The Linux binary links against glibc and libstdc++ at fixed paths.
  nativeBuildInputs = lib.optional stdenv.isLinux pkgs.autoPatchelfHook;
  buildInputs = lib.optional stdenv.isLinux stdenv.cc.cc.lib;

  # The macOS binary carries a linker-signed ad-hoc signature that `strip`
  # would invalidate, leaving a binary the kernel refuses to exec.
  dontStrip = stdenv.isDarwin;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/lightpanda
    runHook postInstall
  '';

  meta = {
    description = "Headless browser designed for AI and automation";
    homepage = "https://lightpanda.io";
    license = lib.licenses.agpl3Only;
    mainProgram = "lightpanda";
    platforms = [
      "aarch64-darwin"
      "x86_64-linux"
    ];
  };
}
