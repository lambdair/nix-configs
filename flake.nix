{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = inputs.nixpkgs.lib.genAttrs systems;
    in
    {
      nixosConfigurations = {
        NixOS = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./host/daiquiri ];
        };
        WSL = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            inputs.nixos-wsl.nixosModules.default
            ./host/sol-cubano
          ];
        };
      };

      darwinConfigurations = {
        MacOS = inputs.nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./host/sonora
          ];
          specialArgs = {
            inherit inputs;
          };
        };
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = inputs.self.darwinConfigurations."simple".pkgs;

      homeConfigurations =
        let
          system = "x86_64-linux";
          sources = inputs.nixpkgs.legacyPackages.${system}.callPackage ./_sources/generated.nix { };
        in
        {
          NixHome = inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = import inputs.nixpkgs {
              system = system;
              config.allowUnfree = true;
              overlays = [
                inputs.rust-overlay.overlays.default
                inputs.emacs-overlay.overlay
              ];
            };
            extraSpecialArgs = {
              inherit inputs sources;
            };
            modules = [
              ./home
              ./home/linux
              inputs.catppuccin.homeModules.catppuccin
              inputs.nixvim.homeManagerModules.nixvim
            ];
          };
          MacHome = inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = import inputs.nixpkgs {
              system = "aarch64-darwin";
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
              ./home
              ./home/mac
              inputs.catppuccin.homeManagerModules.catppuccin
              inputs.nixvim.homeManagerModules.nixvim
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
              nushell
              zellij
              helix
              nil
              yazi
              lazygit
              delta
              git
              jujutsu
            ];
            EDITOR = "hx";
            shellHook = ''
              exec zellij options --default-shell nu "$@"
            '';
          };
        }
      );

      formatter = forAllSystems (system: inputs.nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
    };
}
