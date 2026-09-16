# television's theme for the selected flower.
{ config, lib, ... }:
let
  cfg = config.flowerTheme;
  flowerLib = import ../lib.nix { inherit lib; };
  v = flowerLib.variant cfg.flower (flowerLib.resolve cfg.mode);
  r = v.hex.roles;
in
{
  config = lib.mkIf (cfg.flower != null) {
    catppuccin.television.enable = false;

    programs.television = {
      themes.${v.name} = {
        background = r.bg;
        border_fg = r.guide;
        text_fg = r.text;
        dimmed_text_fg = r.comment;
        input_text_fg = r.keyword;
        result_count_fg = r.keyword;
        result_name_fg = r.function;
        result_line_number_fg = r.constant;
        result_value_fg = r.text;
        selection_fg = r.text;
        selection_bg = r.cursorline;
        match_fg = r.warning;
        preview_title_fg = r.keyword;
        channel_mode_fg = r.bg;
        channel_mode_bg = r.keyword;
        remote_control_mode_fg = r.bg;
        remote_control_mode_bg = r.info;
      };
      settings.ui.theme = v.name;
    };
  };
}
