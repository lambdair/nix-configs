{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    catppuccin.url = "github:catppuccin/nix";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
    };
  };

  outputs =
    inputs:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = inputs.nixpkgs.lib.genAttrs systems;
    in
    {
      nixosConfigurations = {
        myNixOS = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./configuration.nix ];
        };
      };

      homeConfigurations = {
        myHome = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import inputs.nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
            overlays = [
              inputs.rust-overlay.overlays.default
              inputs.emacs-overlay.overlay
            ];
          };
          extraSpecialArgs = {
            inherit inputs;
          };
          modules = [
            ./home.nix
            inputs.catppuccin.homeManagerModules.catppuccin
          ];
        };
      };

      devShells = forAllSystems (
        system:
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              helix
              nil
              yazi
              lazygit
              delta
              git
              jujutsu
            ];
            shellHook = ''
              exec ${pkgs.nushell}/bin/nu
            '';
          };
        }
      );

      formatter = forAllSystems (system: inputs.nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
    };
}
