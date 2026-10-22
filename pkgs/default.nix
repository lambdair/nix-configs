# Custom package definitions shared between home-manager modules and the
# flake's packages output, so both evaluate the exact same derivations.
{ pkgs, sources }:
import ./helix-steel.nix { inherit pkgs sources; }
// {
  lightpanda = import ./lightpanda.nix { inherit pkgs sources; };
  miditui = import ./miditui.nix { inherit pkgs sources; };
  racket-with-langserver = import ./racket-langserver.nix { inherit pkgs sources; };
}
