{ trivialBuild, sources }:

trivialBuild {
  pname = "lsp-proxy";
  version = sources.lsp-proxy.version;
  src = sources.lsp-proxy.src;
  packageRequires = [ ];
}
