{ pkgs }:

pkgs.vimUtils.buildVimPlugin {
  name = "nordic";
  version = "0.1.0";
  src = pkgs.fetchFromGitHub {
    owner = "AlexvZyl";
    repo = "nordic.nvim";
    rev = "1ee4044077059b34eacd18d93613495a602c131f";
    hash = "sha256-x7f7uG4UP3FccXz/uVpLBNScoEsag+M8St4smdWceak=";
  };
}
