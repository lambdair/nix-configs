# terminal-browser: browser that renders inside an existing terminal. Not in
# nixpkgs, and the release archive bundles its own Electron plus native
# helpers, so it is repackaged per platform.
{ pkgs, sources }:

let
  inherit (pkgs) lib stdenv;
  source = if stdenv.isDarwin then sources.terminal-browser-mac else sources.terminal-browser-linux;
in
stdenv.mkDerivation {
  pname = "terminal-browser";
  inherit (source) version src;

  dontConfigure = true;
  dontBuild = true;

  # The bundled Electron links against the desktop stack at fixed paths.
  nativeBuildInputs = lib.optional stdenv.isLinux pkgs.autoPatchelfHook;
  buildInputs = lib.optionals stdenv.isLinux (
    with pkgs;
    [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      dbus
      expat
      glib
      gtk3
      libgbm
      libxkbcommon
      nspr
      nss
      pango
      stdenv.cc.cc.lib
      systemd
      xorg.libX11
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXrandr
      xorg.libxcb
    ]
  );

  # Everything shipped is already built: stripping invalidates the ad-hoc
  # signatures on the macOS Electron helpers and gains nothing on Linux.
  dontStrip = true;

  # `bin/terminal-browser` locates the Electron bundle, the CLI and the native
  # helpers relative to its own `$0`, so the archive stays whole and the entry
  # point on PATH hands over the real path rather than its own.
  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec $out/bin
    cp -R . $out/libexec/terminal-browser

    cat > $out/bin/terminal-browser <<EOF
    #!${stdenv.shell}
    exec $out/libexec/terminal-browser/bin/terminal-browser "\$@"
    EOF
    chmod +x $out/bin/terminal-browser

    runHook postInstall
  '';

  meta = {
    description = "Browser that runs directly inside your existing terminal";
    homepage = "https://github.com/zenbu-labs/terminal-browser";
    license = lib.licenses.mit;
    mainProgram = "terminal-browser";
    platforms = [
      "aarch64-darwin"
      "x86_64-linux"
    ];
  };
}
