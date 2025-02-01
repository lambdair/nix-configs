{ trivialBuild, sources }:

trivialBuild {
  pname = "eglot-booster";
  version = sources.eglot-booster.version;
  src = sources.eglot-booster.src;
  packageRequires = [ ];
}
