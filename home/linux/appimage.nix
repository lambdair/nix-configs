# Wrap an AppImage into a package that also carries its desktop entry and
# icons. appimageTools.wrapType2 only produces the executable, so the entry and
# icons have to be lifted out of a separately extracted copy of the same image.
{ pkgs, lib }:

{
  pname,
  # nvfetcher source: supplies version + src
  source,
  # path of the .desktop file inside the image; installed as <pname>.desktop
  desktop,
  # { from, to }: from is relative to the image root, to is relative to
  # $out/share/icons. The two differ when the image ships an icon under a name
  # or a size directory we do not want to keep.
  icons ? [ ],
  # appended verbatim, for images needing more than the above
  extraInstall ? "",
}:

let
  contents = pkgs.appimageTools.extractType2 {
    inherit pname;
    inherit (source) version src;
  };
in
pkgs.appimageTools.wrapType2 {
  inherit pname;
  inherit (source) version src;

  extraInstallCommands = ''
    install -m 444 -D ${contents}/${desktop} $out/share/applications/${pname}.desktop
  ''
  + lib.concatMapStrings (icon: ''
    install -m 444 -D ${contents}/${icon.from} $out/share/icons/${icon.to}
  '') icons
  + extraInstall;
}
