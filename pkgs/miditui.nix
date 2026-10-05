# miditui: terminal MIDI player and piano roll visualizer (Rust/Ratatui).
# Not in nixpkgs, so build from the nvfetcher-tracked commit.
{ pkgs, sources }:

pkgs.rustPlatform.buildRustPackage {
  pname = "miditui";
  inherit (sources.miditui) version src;
  cargoLock.lockFile = "${sources.miditui.src}/Cargo.lock";

  # cpal plays through ALSA on Linux.
  nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.pkg-config ];
  buildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.alsa-lib ];
}
