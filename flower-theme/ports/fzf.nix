# fzf's colours for the selected flower, passed through FZF_DEFAULT_OPTS.
{ config, lib, ... }:
let
  cfg = config.flowerTheme;
  flowerLib = import ../lib.nix { inherit lib; };
  v = flowerLib.variant cfg.flower (flowerLib.resolve cfg.mode);
  r = v.hex.roles;
in
{
  config = lib.mkIf (cfg.flower != null) {
    catppuccin.fzf.enable = false;

    programs.fzf.colors = {
      bg = r.bg;
      "bg+" = r.cursorline;
      fg = r.text;
      "fg+" = r.text;
      hl = r.warning;
      "hl+" = r.warning;
      info = r.comment;
      prompt = r.keyword;
      pointer = r.keyword;
      marker = r.added;
      spinner = r.special;
      header = r.type;
      border = r.guide;
      gutter = r.bg;
    };
  };
}
