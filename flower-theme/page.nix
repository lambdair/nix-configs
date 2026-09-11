# The palette overview page. The checker's verdicts are shown rather than
# enforced, so a failing palette can still be inspected here.
{ pkgs }:
let
  src = pkgs.lib.fileset.toSource {
    root = ./.;
    fileset = pkgs.lib.fileset.unions [
      ./check.bb
      ./page.bb
    ];
  };
in
pkgs.runCommand "flower-palette" { nativeBuildInputs = [ pkgs.babashka ]; } ''
  export HOME=$TMPDIR
  bb ${src}/check.bb ${import ./variants.nix { inherit pkgs; }} --report report.json || true
  mkdir -p $out
  bb ${src}/page.bb report.json > $out/index.html
''
