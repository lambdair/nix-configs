local wezterm = require("wezterm")

return {
  -- Theme
  color_scheme = "Catppuccin Frappe",

  -- Font
  font = wezterm.font_with_fallback({
    { family = "Uiua386" },
    { family = "Rounded Mgen+ 2m" }
  }),
  font_size = 14,

  -- Tab
  hide_tab_bar_if_only_one_tab = true,

  -- Misc
  use_ime = true,
  audible_bell = "Disabled",
}
