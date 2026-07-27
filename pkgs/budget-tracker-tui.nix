# budget_tracker_tui: TUI budget tracking application.
{ pkgs, sources }:

pkgs.rustPlatform.buildRustPackage {
  inherit (sources.budget_tracker_tui) pname version src;
  cargoLock.lockFile = "${sources.budget_tracker_tui.src}/Cargo.lock";
}
