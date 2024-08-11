{
  pkgs,
  trivialBuild,
  fetchgit,
  sources,
}:

trivialBuild {
  pname = "typst-preview";
  version = sources.typst-preview.version;
  src = sources.typst-preview.src;
  packageRequires = [ pkgs.emacsPackages.websocket ];
}
