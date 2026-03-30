{ config, pkgs, ... }:

{
  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      trusted-users = [
        "root"
        "lambdair"
      ];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://devenv.cachix.org"
        "https://lambdair.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "lambdair.cachix.org-1:54ySwbQBraOrS9rspPG7Ir31xvKwLBzY3rv7ovkvBIA="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.lambdair = {
    isNormalUser = true;
    description = "Ziyu Guo";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.nushell;
  };

  environment.shells = [ pkgs.nushell ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    helix
    nushell
    git
    home-manager
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
