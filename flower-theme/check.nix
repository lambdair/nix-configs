# Runs the checker's tests, then the checker over every palette.
{ pkgs }:
let
  src = pkgs.lib.fileset.toSource {
    root = ./.;
    fileset = pkgs.lib.fileset.unions [
      ./check.bb
      ./check_test.bb
    ];
  };
in
pkgs.runCommand "flower-theme-check" { nativeBuildInputs = [ pkgs.babashka ]; } ''
  export HOME=$TMPDIR
  bb ${src}/check_test.bb
  bb ${src}/check.bb ${import ./variants.nix { inherit pkgs; }}
  touch $out
''
