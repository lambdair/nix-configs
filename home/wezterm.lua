local wezterm = require("wezterm")

-- flower.lua, when present, names the flower theme's dark and light schemes.
local function color_scheme()
  local ok, flower = pcall(require, "flower")
  if not ok then
    return "Catppuccin Frappe"
  end
  local appearance = wezterm.gui and wezterm.gui.get_appearance() or "Dark"
  if appearance:find("Dark") then
    return flower.dark
  end
  return flower.light
end

return {
  -- Theme
  color_scheme = color_scheme(),

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
