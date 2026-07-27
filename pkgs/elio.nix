# elio: snappy, batteries-included terminal file manager (Rust/Ratatui).
# Not in nixpkgs yet, so build from the nvfetcher-tracked release.
{ pkgs, sources }:

pkgs.rustPlatform.buildRustPackage {
  pname = "elio";
  inherit (sources.elio) version src;
  cargoLock.lockFile = "${sources.elio.src}/Cargo.lock";

  # Some tests need a real terminal (Sixel rendering), a working trash, audio
  # preview timing, or process-group control — none available in the sandbox.
  doCheck = false;
}
