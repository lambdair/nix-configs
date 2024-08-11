{
  trivialBuild,
  fetchgit,
  markdown-mode,
  sources,
}:

trivialBuild {
  pname = "nael";
  version = sources.nael.version;
  src = sources.nael.src;
  packageRequires = [ markdown-mode ];
}
