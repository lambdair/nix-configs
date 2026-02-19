{ pkgs, sources, ... }:

# let
#   awrit = pkgs.stdenv.mkDerivation {
#     inherit (sources.awrit) pname version src;
#
#     installPhase = ''
#       mkdir -p $out/Applications $out/bin
#       cp -r lib/awrit/awrit.app $out/Applications/
#       ln -s $out/Applications/awrit.app/Contents/MacOS/awrit $out/bin/awrit
#     '';
#   };
# in
rec {
  home.username = "lambdair";
  home.homeDirectory = "/Users/${home.username}";

  home.packages = with pkgs; [
    macskk # Japanese SKK input method for macOS
    # awrit # Chromium-based browser for Kitty terminal
  ];
}
