{
  trivialBuild,
  sources,
}:

trivialBuild {
  pname = "typst-ts-mode";
  version = sources.typst-ts-mode.version;
  src = sources.typst-ts-mode.src;
  packageRequires = [ ];
}
