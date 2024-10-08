{
  description = "Common Lisp editor/IDE with high expansibility";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell rec {
          packages = with pkgs; [
            sbcl
            sbclPackages.qlot-cli
            ncurses
            openssl
            SDL2
            SDL2_ttf
            SDL2_image
            libffi
          ];
          path = nixpkgs.lib.makeLibraryPath packages;
          shellHook = ''
            export LD_LIBRARY_PATH=${path}
          '';
        };

        packages.default = pkgs.stdenv.mkDerivation {
          name = "lem";
          src = ./.;
          buildInputs = with pkgs; [
            sbcl
            sbclPackages.qlot-cli
            which
          ];
          buildPhase = ''
            make sdl2-ncurses
          '';
          installPhase = '''';
        };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
