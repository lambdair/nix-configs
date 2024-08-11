{ trivialBuild, fetchgit }:

trivialBuild {
  pname = "eglot-booster";
  version = "main-2024-8-16";
  src = fetchgit {
    url = "https://github.com/jdtsmith/eglot-booster";
    rev = "e19dd7ea81bada84c66e8bdd121408d9c0761fe6";
    hash = "sha256-vF34ZoUUj8RENyH9OeKGSPk34G6KXZhEZozQKEcRNhs=";
  };
  packageRequires = [ ];
}
