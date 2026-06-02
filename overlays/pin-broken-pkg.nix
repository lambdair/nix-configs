inputs: final: prev:
let
  pkgs-pinned = import inputs.nixpkgs-pinned {
    system = prev.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  oxker = pkgs-pinned.oxker;
  # 2026.5.0 fails to build on darwin: electron-builder's code-signing calls
  # the macOS `security` CLI (absent in the Nix sandbox) and it pulls insecure
  # electron-39.8.10. Pin to the working 2026.1.0.
  bitwarden-desktop = pkgs-pinned.bitwarden-desktop;
}
