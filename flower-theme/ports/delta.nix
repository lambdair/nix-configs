# delta's styles for the selected flower. Line backgrounds are blended from the
# palette's diff foregrounds, and `syntax` keeps delta's own highlighting for
# the text itself.
{ config, lib, ... }:
let
  cfg = config.flowerTheme;
  flowerLib = import ../lib.nix { inherit lib; };
  v = flowerLib.variant cfg.flower (flowerLib.resolve cfg.mode);
  r = v.hex.roles;
  inherit (flowerLib) mix;
in
{
  config = lib.mkIf (cfg.flower != null) {
    catppuccin.delta.enable = false;

    programs.delta.options = {
      plus-style = "syntax ${mix 0.22 r.bg r.added}";
      minus-style = "syntax ${mix 0.22 r.bg r.removed}";
      plus-emph-style = "syntax ${mix 0.42 r.bg r.added}";
      minus-emph-style = "syntax ${mix 0.42 r.bg r.removed}";
      line-numbers-plus-style = r.added;
      line-numbers-minus-style = r.removed;
      line-numbers-zero-style = r.linenr;
      line-numbers-left-style = r.guide;
      line-numbers-right-style = r.guide;
      file-style = "${r.keyword} bold";
      file-decoration-style = "${r.guide} ul";
      hunk-header-style = "file line-number syntax";
      hunk-header-decoration-style = "${r.guide} box";
      commit-style = "${r.constant} bold";
      commit-decoration-style = "${r.guide} box";
      whitespace-error-style = "${r.bg} ${r.error}";
      blame-palette = "${r.bg} ${r.cursorline} ${r.statusline}";
    };
  };
}
