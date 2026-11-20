inputs: final: prev:
let
  pkgs-pinned = import inputs.nixpkgs-pinned {
    system = prev.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  oxker = pkgs-pinned.oxker;
}
