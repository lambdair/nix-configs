# racket-langserver, placed on the collection path of the racket that helix
# starts it with (`racket -l racket-langserver`).
#
# fixw and html-parsing — the latter needing mcfly — are outside the Racket
# distribution, so `raco pkg install` would pull them from the package catalog,
# which a sandboxed build cannot reach. Vendoring the four collections keeps
# them pinned and lets raco compile them offline; every remaining dependency
# comes with the full racket package.
{ pkgs, sources }:

let
  collections =
    pkgs.runCommand "racket-langserver-collections"
      {
        nativeBuildInputs = [ pkgs.unzip ];
      }
      ''
        mkdir -p $out
        cp -R --no-preserve=mode,ownership ${sources.racket-langserver.src} $out/racket-langserver
        cp -R --no-preserve=mode,ownership ${sources.fixw.src} $out/fixw
        # These ship as zips holding their collection directory at the root.
        unzip -q ${sources.html-parsing.src} -d $out
        unzip -q ${sources.mcfly.src} -d $out
        unzip -q ${sources.overeasy.src} -d $out
      '';

  compiled =
    pkgs.runCommand "racket-langserver-${sources.racket-langserver.version}"
      {
        nativeBuildInputs = [ pkgs.racket ];
      }
      ''
        cp -R --no-preserve=mode,ownership ${collections} $out
        export HOME="$TMPDIR"
        export PLTCOLLECTS=":$out"
        raco make $out/racket-langserver/main.rkt
      '';
in
pkgs.symlinkJoin {
  name = "racket-with-langserver-${pkgs.racket.version}";
  paths = [ pkgs.racket ];
  nativeBuildInputs = [ pkgs.makeWrapper ];
  # A leading colon keeps the distribution's own collections on the path.
  postBuild = ''
    wrapProgram $out/bin/racket --set PLTCOLLECTS ":${compiled}"
  '';
}
