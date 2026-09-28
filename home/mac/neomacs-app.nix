{
  config,
  pkgs,
  inputs,
  ...
}:

let
  neomacs = inputs.neomacs.packages.${pkgs.stdenv.hostPlatform.system}.default;
  # Finder, Spotlight and the Dock launch only bundles, and neomacs's package
  # ships none. The bundle execs the profile's emacs, the build carrying the
  # packages from ../emacs. LaunchServices keeps the exec'd process under this
  # bundle, so the Dock and the menu bar show it under this bundle's name.
  neomacs-app =
    pkgs.runCommand "neomacs-app"
      {
        nativeBuildInputs = [
          pkgs.librsvg
          pkgs.libicns
        ];
      }
      ''
        contents="$out/Applications/NEO Emacs.app/Contents"
        mkdir -p "$contents/MacOS" "$contents/Resources"

        cat > "$contents/MacOS/neomacs" <<EOF
        #!/bin/sh
        exec ${config.home.profileDirectory}/bin/emacs "\$@"
        EOF
        chmod +x "$contents/MacOS/neomacs"

        cat > "$contents/Info.plist" <<EOF
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>CFBundleName</key>
          <string>NEO Emacs</string>
          <key>CFBundleDisplayName</key>
          <string>NEO Emacs</string>
          <key>CFBundleExecutable</key>
          <string>neomacs</string>
          <key>CFBundleIdentifier</key>
          <string>org.neomacs</string>
          <key>CFBundleVersion</key>
          <string>${neomacs.version}</string>
          <key>CFBundlePackageType</key>
          <string>APPL</string>
          <key>CFBundleInfoDictionaryVersion</key>
          <string>6.0</string>
          <key>CFBundleIconFile</key>
          <string>neomacs</string>
          <key>NSHighResolutionCapable</key>
          <true/>
        </dict>
        </plist>
        EOF

        for size in 16 32 48 128 256 512; do
          rsvg-convert -w $size -h $size \
            ${neomacs}/share/neomacs/etc/images/icons/hicolor/scalable/apps/emacs.svg \
            -o icon_$size.png
        done
        png2icns "$contents/Resources/neomacs.icns" icon_*.png
      '';
in
{
  home.packages = [ neomacs-app ];
}
