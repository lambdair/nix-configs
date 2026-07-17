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
  # 0.24.0 cannot link on aarch64-darwin: cctools `ld` dies with SIGTRAP
  # ("Trace/BPT trap: 5") on its final binary. Pin to 0.22.1, which still
  # substitutes from the binary cache.
  spotify-player = pkgs-pinned.spotify-player;
}
