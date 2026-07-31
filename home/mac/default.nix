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
  imports = [
    ./zmk-battery-center.nix
  ];

  home.username = "lambdair";
  home.homeDirectory = "/Users/${home.username}";

  home.packages = with pkgs; [
    macskk # Japanese SKK input method for macOS
    # awrit # Chromium-based browser for Kitty terminal
    obsidian # Knowledge base
    bitwarden-desktop # pinned in overlays/pin-broken-pkg.nix
    cmux # Ghostty-based terminal for coding agents
  ];

  programs.nushell.extraEnv = ''
    # Set up Nix paths for non-login contexts (e.g. Ghostty launching nushell directly)
    if not ("__NIX_DARWIN_SET_ENVIRONMENT_DONE" in $env) {
      $env.PATH = ($env.PATH | prepend [
        $"($env.HOME)/.nix-profile/bin"
        "/run/current-system/sw/bin"
        "/nix/var/nix/profiles/default/bin"
      ])
    }

    # Expose tools installed outside Nix (e.g. Heptabase CLI shim in /usr/local/bin)
    if ("/usr/local/bin" not-in $env.PATH) {
      $env.PATH = ($env.PATH | append "/usr/local/bin")
    }
  '';
}
