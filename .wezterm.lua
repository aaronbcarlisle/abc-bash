local wezterm = require 'wezterm'

-- config_builder gives real errors on typo'd option names instead of silently
-- ignoring them, which is how most bogus wezterm settings survive on the internet
local config = wezterm.config_builder()

local is_windows = wezterm.target_triple:find 'windows' ~= nil

-- -- Shell --

-- git bash as a login shell so it sources ~/.bash_profile / ~/.bashrc
if is_windows then
	config.default_prog = { 'C:\\Program Files\\Git\\bin\\bash.exe', '-l', '-i' }
end

-- -- Rendering --

-- WebGpu is not the default (it was made default in 20240127 and reverted one
-- day later in 20240128), so this is opt-in. If you hit stutter or input lag,
-- delete this block; the default OpenGL path on windows already goes through
-- ANGLE -> Direct3D and is the safer choice.
config.front_end = 'WebGpu'

-- on windows WebGpu tends to pick the Vulkan backend, which benchmarks worse
-- than Dx12. pin the discrete Dx12 adapter explicitly. falls through harmlessly
-- on linux where no Dx12 adapter exists
for _, gpu in ipairs(wezterm.gui.enumerate_gpus()) do
	if gpu.backend == 'Dx12' and gpu.device_type == 'DiscreteGpu' then
		config.webgpu_preferred_adapter = gpu
		break
	end
end

-- only a hint, and only applies to WebGpu. prefers the dedicated gpu
config.webgpu_power_preference = 'HighPerformance'

-- this is a ceiling, not a target. setting it above your panel refresh rate
-- buys nothing but extra wakeups. default is 60
config.max_fps = 165

-- disables easing on cursor blink / blinking text / visual bell. the docs
-- recommend this for the software renderer specifically, so on gpu rendering
-- it is close to free and close to worthless. the Constant pair is required or
-- the blink turns into a chunky stepped fade
config.animation_fps = 1
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'

-- transparency and the win11 backdrops force per-frame DWM compositing, which
-- is a real cost on windows. leave these alone
config.window_background_opacity = 1.0

-- -- Caches --

-- cache misses during fast scroll cost more than frame rate caps do. these
-- options are absent from the website but present in config.rs and valid since
-- well before the 20240203 stable. all default to 1024 (glyph image: 256).
-- measure before tuning further: wezterm --config periodic_stat_logging=10
config.shape_cache_size = 4096
config.line_state_cache_size = 4096
config.line_quad_cache_size = 4096
config.line_to_ele_shape_cache_size = 4096
config.glyph_cache_image_cache_size = 1024

-- -- Window --

-- cosmetic, not a performance setting. the titlebar is drawn by DWM and never
-- touches wezterm's render path. keep RESIZE in the set or you lose resizing
-- and minimize on windows
config.window_decorations = 'RESIZE'

-- history, not speed. render cost scales with the viewport, not the scrollback.
-- default is 3500; this is a small memory cost for more backlog
config.scrollback_lines = 5000

config.enable_scroll_bar = false

-- one less background http call on startup
config.check_for_updates = false

-- -- Font --

config.font = wezterm.font_with_fallback {
	-- wezterm appends Noto Color Emoji and Symbols Nerd Font Mono after this
	-- list automatically, so nerd font glyphs still resolve
	{ family = 'JetBrains Mono' },
}

-- uncomment to disable ligatures if they get in the way while editing. scoped
-- per font above is also valid, this applies globally
-- config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }

-- -- Key Bindings --

config.keys = {
	-- shift+enter inserts a newline in claude code (sends ctrl+j / line feed)
	{ key = 'Enter', mods = 'SHIFT', action = wezterm.action.SendString '\n' },

	-- pane splits. note wezterm's naming: SplitHorizontal arranges panes
	-- side by side, SplitVertical stacks them top over bottom
	-- keys are lowercase because `key` is the literal character produced, and
	-- without shift in the combo that character is lowercase. uppercase would
	-- silently require shift as well
	{ key = 'v', mods = 'CTRL|ALT', action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
	{ key = 's', mods = 'CTRL|ALT', action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' } },

	-- vim-style ctrl+shift+h/j/k/l jumps between panes
	{ key = 'H', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection 'Left' },
	{ key = 'J', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection 'Down' },
	{ key = 'K', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection 'Up' },
	{ key = 'L', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection 'Right' },
}

return config
