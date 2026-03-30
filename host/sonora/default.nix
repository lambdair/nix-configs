{ inputs, pkgs, ... }:

{
  nix.package = pkgs.nix;
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
  ];

  # Match existing Nix installation's nixbld group GID.
  ids.gids.nixbld = 30000;

  imports = [ ../cache.nix ];

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina
  programs.zsh.enableGlobalCompInit = false;
  programs.zsh.interactiveShellInit = ''
    autoload -U compinit && compinit -u
    autoload -U bashcompinit && bashcompinit
  '';

  # Set Git commit hash for darwin-version.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;
}
