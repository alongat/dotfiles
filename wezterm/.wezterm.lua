local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- config.font = wezterm.font("FiraCode Nerd Font Mono")
-- config.font = wezterm.font("Monaspace Argon")
config.font = wezterm.font("Monaspace Neon Var")
config.font_size = 18

config.color_scheme = "Tokyo Night"

config.window_decorations = "RESIZE"

config.window_background_opacity = 0.97
config.macos_window_background_blur = 50

config.keys = {
	{ key = "RightArrow", mods = "ALT", action = wezterm.action({ SendKey = { key = "f", mods = "ALT" } }) },
	{ key = "LeftArrow", mods = "ALT", action = wezterm.action({ SendKey = { key = "b", mods = "ALT" } }) },
}

return config
