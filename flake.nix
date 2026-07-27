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
    moonbit-overlay = {
      url = "github:moonbit-community/moonbit-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wezterm = {
      url = "github:wez/wezterm/main?dir=nix";
    };
    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Deliberately not following nixpkgs: nixpkgs 26.11 dropped x86_64-darwin,
    # but hunk takes its systems from nix-systems/default, which still lists it.
    # Evaluating hunkdiff forces that system's flake-parts outputs, so following
    # our nixpkgs makes it throw even on aarch64-darwin.
    hunk = {
      url = "github:modem-dev/hunk";
    };
    private = {
      url = "git+ssh://git@git.sr.ht/~lambdair/nix-private";
    };
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
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
      darwinPkgs = import inputs.nixpkgs {
        system = "aarch64-darwin";
        config.allowUnfree = true;
        config.allowUnsupportedSystem = true;
        overlays = [
          inputs.rust-overlay.overlays.default
          inputs.emacs-overlay.overlay
          inputs.claude-code-nix.overlays.default
          inputs.moonbit-overlay.overlays.default
          (import ./overlays/uiua386-fix-monospace.nix)
          (import ./overlays/pin-broken-pkg.nix inputs)
        ];
      };
      sourcesFor =
        system: inputs.nixpkgs.legacyPackages.${system}.callPackage ./_sources/generated.nix { };
      darwinSources = sourcesFor "aarch64-darwin";
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
            inputs.lix-module.darwinModules.lixFromNixpkgs
          ];
          specialArgs = {
            inherit inputs;
          };
        };
      };

      homeConfigurations =
        let
          system = "x86_64-linux";
          sources = sourcesFor system;
          linuxPkgs = import inputs.nixpkgs {
            system = system;
            config.allowUnfree = true;
            overlays = [
              inputs.rust-overlay.overlays.default
              inputs.emacs-overlay.overlay
              inputs.claude-code-nix.overlays.default
              inputs.moonbit-overlay.overlays.default
              (import ./overlays/pin-broken-pkg.nix inputs)
            ];
          };
          linuxHome =
            platformModule:
            inputs.home-manager.lib.homeManagerConfiguration {
              pkgs = linuxPkgs;
              extraSpecialArgs = {
                inherit inputs sources;
              };
              modules = [
                ./home
                platformModule
                inputs.catppuccin.homeModules.catppuccin
              ];
            };
        in
        {
          NixHome = linuxHome ./home/linux;
          WSLHome = linuxHome ./home/wsl;
          MacHome = inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = darwinPkgs;
            extraSpecialArgs = {
              inherit inputs;
              sources = darwinSources;
            };
            modules = [
              ./home
              ./home/mac
              inputs.catppuccin.homeModules.catppuccin
              inputs.private.homeModules.mac
            ];
          };
        };

      # Aggregate of the expensive custom builds, for CI to build and push to
      # the binary cache. References only public-source packages, so building
      # this output (`nix build .#ci-heavy`) never fetches the private input;
      # flake-wide commands like `nix flake check` still resolve every locked
      # input and need its credentials. darwinPkgs/darwinSources are shared
      # with MacHome, keeping the derivations hash-identical so CI artifacts
      # substitute locally.
      packages."aarch64-darwin".ci-heavy =
        let
          customPkgs = import ./pkgs {
            pkgs = darwinPkgs;
            sources = darwinSources;
          };
        in
        darwinPkgs.linkFarm "ci-heavy" [
          {
            name = "steel";
            path = customPkgs.steel;
          }
          {
            name = "helix-steel-unwrapped";
            path = customPkgs.helix-steel-unwrapped;
          }
          {
            name = "helix-runtime";
            path = customPkgs.helix-runtime;
          }
          {
            name = "sulafat";
            path = customPkgs.sulafat;
          }
          {
            name = "difit";
            path = customPkgs.difit;
          }
          {
            name = "hunkdiff";
            path = inputs.hunk.packages."aarch64-darwin".default;
          }
        ];

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
