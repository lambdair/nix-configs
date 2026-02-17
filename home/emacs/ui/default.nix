{
  pkgs,
  epkgs,
  sources,
}:

let
  jj-mode = pkgs.callPackage ./jj-mode.nix {
    inherit (pkgs.emacs.pkgs) trivialBuild magit;
    inherit sources;
  };
in
with epkgs;
[
  neotree
  catppuccin-theme
  nord-theme
  nerd-icons
  nerd-icons-completion
  doom-modeline
  dashboard
  jj-mode
  nano-theme
  doom-themes
  modus-themes
]
