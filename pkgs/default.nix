# Custom package definitions shared between home-manager modules and the
# flake's packages output, so both evaluate the exact same derivations.
{ pkgs, sources }:
import ./helix-steel.nix { inherit pkgs sources; }
// {
  difit = import ./difit.nix { inherit pkgs sources; };
  druk = import ./druk.nix { inherit pkgs sources; };
  elio = import ./elio.nix { inherit pkgs sources; };
  lightpanda = import ./lightpanda.nix { inherit pkgs sources; };
  racket-with-langserver = import ./racket-langserver.nix { inherit pkgs sources; };
}
