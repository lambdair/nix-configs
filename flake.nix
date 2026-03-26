{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-pinned.url = "github:NixOS/nixpkgs/aca4d95fce4914b3892661bcb80b8087293536c6";
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
    };
    nixvim = {
      url = "github:nix-community/nixvim";
    };
    wezterm = {
      url = "github:wez/wezterm/main?dir=nix";
    };
    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    private = {
      url = "git+ssh://git@git.sr.ht/~lambdair/nix-private";
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
            inputs.private.darwinModules.default
          ];
          specialArgs = {
            inherit inputs;
          };
        };
      };

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
                inputs.claude-code-nix.overlays.default
                (import ./overlays/pin-broken-pkg.nix inputs)
              ];
            };
            extraSpecialArgs = {
              inherit inputs sources;
            };
            modules = [
              ./home
              ./home/linux
              inputs.catppuccin.homeModules.catppuccin
              inputs.nixvim.homeModules.nixvim
            ];
          };
          MacHome =
            let
              macSources =
                inputs.nixpkgs.legacyPackages."aarch64-darwin".callPackage ./_sources/generated.nix
                  { };
            in
            inputs.home-manager.lib.homeManagerConfiguration {
              pkgs = import inputs.nixpkgs {
                system = "aarch64-darwin";
                config.allowUnfree = true;
                config.allowUnsupportedSystem = true;
                overlays = [
                  inputs.rust-overlay.overlays.default
                  inputs.emacs-overlay.overlay
                  inputs.claude-code-nix.overlays.default
                  (import ./overlays/uiua386-fix-monospace.nix)
                  (import ./overlays/pin-broken-pkg.nix inputs)
                ];
              };
              extraSpecialArgs = {
                inherit inputs;
                sources = macSources;
              };
              modules = [
                ./home
                ./home/mac
                inputs.catppuccin.homeModules.catppuccin
                inputs.nixvim.homeModules.nixvim
                inputs.private.homeModules.mac
              ];
            };
        };

      devShells = forAllSystems (
        system:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [
              inputs.claude-code-nix.overlays.default
            ];
          };
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
              just
              nvfetcher
              home-manager
              claude-code
            ];
            EDITOR = "hx";
            shellHook = ''
              exec zellij options --default-shell nu "$@"
            '';
          };
        }
      );

      formatter = forAllSystems (system: inputs.nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
