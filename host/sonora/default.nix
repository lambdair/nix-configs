{ inputs, ... }:

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
  ];

  # Match existing Nix installation's nixbld group GID.
  ids.gids.nixbld = 30000;

  imports = [ ../cache.nix ];

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Authenticate sudo with Touch ID. sudo_local writes /etc/pam.d/sudo_local,
  # which the base sudo PAM config includes and macOS updates leave untouched.
  security.pam.services.sudo_local.touchIdAuth = true;

  # base.nix's gc settings are NixOS-only, so darwin needs its own. nix-darwin
  # refuses `nix.settings.auto-optimise-store` (it can corrupt the store), so
  # dedup runs via periodic `nix.optimise`. Both default to weekly.
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 7d";
  };
  nix.optimise.automatic = true;

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
