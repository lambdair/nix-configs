{
  trivialBuild,
  sources,
  magit,
}:

trivialBuild {
  pname = "jj-mode";
  version = sources.jj-mode.version;
  src = sources.jj-mode.src;
  packageRequires = [ magit ];
}
