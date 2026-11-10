# tuicr themes for the selected flower: a local theme per variant.
{ config, lib, ... }:
let
  cfg = config.flowerTheme;
  flowerLib = import ../lib.nix { inherit lib; };
  inherit (flowerLib) mix;

  theme =
    v:
    let
      r = v.hex.roles;
    in
    ''
      panel_bg = "${r.bg}"
      bg_highlight = "${r.selection}"
      fg_primary = "${r.text}"
      fg_secondary = "${r.subtext}"
      fg_dim = "${r.comment}"

      diff_add = "${r.added}"
      diff_add_bg = "${mix 0.22 r.bg r.added}"
      diff_del = "${r.removed}"
      diff_del_bg = "${mix 0.22 r.bg r.removed}"
      diff_context = "${r.text}"
      diff_hunk_header = "${r.function}"
      expanded_context_fg = "${r.comment}"

      syntax_add_bg = "${mix 0.16 r.bg r.added}"
      syntax_del_bg = "${mix 0.16 r.bg r.removed}"

      file_added = "${r.added}"
      file_modified = "${r.changed}"
      file_deleted = "${r.removed}"
      file_renamed = "${r.info}"

      reviewed = "${r.added}"
      pending = "${r.changed}"

      comment_note = "${r.function}"
      comment_suggestion = "${r.info}"
      comment_issue = "${r.error}"
      comment_praise = "${r.added}"

      border_focused = "${r.keyword}"
      border_unfocused = "${r.guide}"
      status_bar_bg = "${r.statusline}"
      cursor_color = "${r.special}"
      cursor_line_bg = "${r.cursorline}"
      branch_name = "${r.type}"
      help_indicator = "${r.comment}"

      message_info_fg = "${r.bg}"
      message_info_bg = "${r.info}"
      message_warning_fg = "${r.bg}"
      message_warning_bg = "${r.warning}"
      message_error_fg = "${r.bg}"
      message_error_bg = "${r.error}"
      update_badge_fg = "${r.bg}"
      update_badge_bg = "${r.special}"

      mode_fg = "${r.bg}"
      mode_bg = "${r.keyword}"
    '';

  variants = map (flowerLib.variant cfg.flower) flowerLib.modes;
  name = mode: "flower-${cfg.flower}-${if cfg.mode == "auto" then mode else cfg.mode}";
in
{
  config = lib.mkIf (cfg.flower != null) {
    xdg.configFile =
      lib.listToAttrs (
        map (v: lib.nameValuePair "tuicr/themes/${v.name}.toml" { text = theme v; }) variants
      )
      // {
        # Before the rest: keys after a table header would land in that table.
        "tuicr/config.toml".text = lib.mkBefore ''
          theme_dark = "${name "dark"}"
          theme_light = "${name "light"}"

        '';
      };
  };
}
