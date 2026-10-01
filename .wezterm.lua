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
-- config.front_end = 'WebGpu'

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

-- MACHINE SPECIFIC: set this to your panel's refresh rate. 165 matches a
-- 165hz ultrawide; on a 60hz machine it is harmless (this is a ceiling, not a
-- target) but the headroom goes unused. raising it above your refresh rate
-- buys nothing but extra wakeups. default is 60
config.max_fps = 165

-- disables easing on cursor blink / blinking text / visual bell. the docs
-- recommend this for the software renderer specifically, so on gpu rendering
-- it is close to free and close to worthless. the Constant pair is required or
-- the blink turns into a chunky stepped fade
config.animation_fps = 1
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'

-- no bell: silence the system beep and make the visual bell a no-op, so
-- invalid input (bad completion, backspace on an empty line) doesn't flash.
-- bash's readline "visible" bell is a separate flash; .bashrc turns it off
config.audible_bell = 'Disabled'
config.visual_bell = {
	fade_in_duration_ms = 0,
	fade_out_duration_ms = 0,
}

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
-- and minimize on windows. INTEGRATED_BUTTONS draws minimize/maximize/close
-- at the right end of the tab bar, since RESIZE alone has no title bar
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'

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

-- -- Tab Colors --

-- wezterm has no per-tab color setting, so alt+c stores a color per
-- tab in wezterm.GLOBAL (survives config reloads; only plain values, hence the
-- flat string keys) and format-tab-title below paints it
local tab_colors = {
	{ name = 'Red', hex = '#e06c75' },
	{ name = 'Orange', hex = '#d19a66' },
	{ name = 'Yellow', hex = '#e5c07b' },
	{ name = 'Green', hex = '#98c379' },
	{ name = 'Cyan', hex = '#56b6c2' },
	{ name = 'Blue', hex = '#61afef' },
	{ name = 'Purple', hex = '#c678dd' },
}

local function tab_color_key(tab_id)
	return 'tab_color_' .. tab_id
end

local tab_color_choices = { { id = 'none', label = 'None (reset)' } }
for _, c in ipairs(tab_colors) do
	table.insert(tab_color_choices, {
		id = c.hex,
		label = wezterm.format { { Foreground = { Color = c.hex } }, { Text = '█ ' .. c.name } },
	})
end

-- only colored tabs are formatted here. returning nothing leaves every other
-- tab on wezterm's default title. the active tab is filled with its color,
-- inactive ones just get colored text so the active tab still stands out
wezterm.on('format-tab-title', function(tab, _, _, _, _, max_width)
	local color = wezterm.GLOBAL[tab_color_key(tab.tab_id)]
	if not color then
		return
	end
	local title = tab.tab_title
	if not title or #title == 0 then
		title = tab.active_pane.title
	end
	title = ' ' .. wezterm.truncate_right((tab.tab_index + 1) .. ': ' .. title, max_width - 2) .. ' '
	if tab.is_active then
		return {
			{ Background = { Color = color } },
			{ Foreground = { Color = '#1e1e1e' } },
			{ Text = title },
		}
	end
	return {
		{ Foreground = { Color = color } },
		{ Text = title },
	}
end)

-- -- Pane Moving --

-- wezterm's lua can only move a pane out (alt+d, ctrl+shift+b), not back in. the
-- cli can do both: move-pane-to-new-tab docks a pane into another window and
-- split-pane --move-pane-id joins it into another tab. the gui exports
-- WEZTERM_UNIX_SOCKET into its own environment, so this child finds it
local function wezterm_cli(args)
	local cmd = { wezterm.executable_dir .. (is_windows and '\\wezterm.exe' or '/wezterm'), 'cli' }
	for _, arg in ipairs(args) do
		table.insert(cmd, arg)
	end
	wezterm.background_child_process(cmd)
end

-- shows a picker of every other window (or tab) and hands the chosen id to
-- on_pick. windows are numbered in creation order, tabs as in the tab bar
local function pick_target(window, pane, kind, on_pick)
	local here_window = window:mux_window():window_id()
	local here_tab = pane:tab():tab_id()
	local choices = {}
	for w_index, w in ipairs(wezterm.mux.all_windows()) do
		for t_index, t in ipairs(w:tabs()) do
			local label = 'Window ' .. w_index .. ' / Tab ' .. t_index .. ': ' .. t:active_pane():get_title()
			if kind == 'window' and w:window_id() ~= here_window and t_index == 1 then
				table.insert(choices, { id = tostring(w:window_id()), label = label })
			elseif kind == 'tab' and t:tab_id() ~= here_tab then
				table.insert(choices, { id = tostring(t:active_pane():pane_id()), label = label })
			end
		end
	end
	if #choices == 0 then
		return
	end
	window:perform_action(
		wezterm.action.InputSelector {
			title = kind == 'window' and 'Dock into window' or 'Join as split into tab',
			choices = choices,
			action = wezterm.action_callback(function(_, _, id)
				if id then
					on_pick(id)
				end
			end),
		},
		pane
	)
end

-- -- Key Bindings --

-- each binding carries a `desc`, which feeds the ctrl+shift+/ cheat sheet and
-- the command palette. desc is stripped before these become config.keys (see
-- the end of the file). start each desc with its group so sorting groups them
local keys = {
	-- shift+enter inserts a newline in claude code (sends ctrl+j / line feed).
	-- send_text rather than SendString '\n': the command palette lists a
	-- SendString by printing its text, and a raw newline there has no glyph,
	-- which pops a "Font problem" notice every time the palette opens
	{
		key = 'Enter',
		mods = 'SHIFT',
		desc = 'Claude Code: newline',
		action = wezterm.action_callback(function(_, pane)
			pane:send_text '\n'
		end),
	},

	-- pane splits. note wezterm's naming: SplitHorizontal arranges panes
	-- side by side, SplitVertical stacks them top over bottom
	-- keys are lowercase because `key` is the literal character produced, and
	-- without shift in the combo that character is lowercase. uppercase would
	-- silently require shift as well
	{ key = 'v', mods = 'CTRL|ALT', action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' }, desc = 'Pane: split left | right' },
	{ key = 's', mods = 'CTRL|ALT', action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' }, desc = 'Pane: split top / bottom' },

	-- vim-style ctrl+shift+h/j/k/l jumps between panes
	{ key = 'H', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection 'Left', desc = 'Pane: focus left' },
	{ key = 'J', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection 'Down', desc = 'Pane: focus down' },
	{ key = 'K', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection 'Up', desc = 'Pane: focus up' },
	{ key = 'L', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection 'Right', desc = 'Pane: focus right' },

	-- alt+r renames the current tab. submitting an empty name clears it and
	-- goes back to the title the running program sets. no default binding
	-- exists for this
	{
		key = 'r',
		mods = 'ALT',
		desc = 'Tab: rename',
		action = wezterm.action.PromptInputLine {
			description = 'Rename tab (empty to reset)',
			action = wezterm.action_callback(function(window, _, line)
				-- line is nil when the prompt is cancelled with escape
				if line then
					window:active_tab():set_title(line)
				end
			end),
		},
	},

	-- alt+d detaches the current pane into its own window. for a tab with no
	-- splits that moves the whole tab. wezterm can't drag tabs out
	{
		key = 'd',
		mods = 'ALT',
		desc = 'Pane: move to its own window',
		action = wezterm.action_callback(function(_, pane)
			pane:move_to_new_window()
		end),
	},

	-- ctrl+shift+b breaks the current pane out of its split into its own tab
	{
		key = 'B',
		mods = 'CTRL|SHIFT',
		desc = 'Pane: move to its own tab',
		action = wezterm.action_callback(function(_, pane)
			pane:move_to_new_tab()
		end),
	},

	-- ctrl+shift+d docks the current pane into another window as a new tab,
	-- the reverse of alt+d. a window left with no panes closes. not plain
	-- ctrl+d: that's end-of-input, which exits bash, python and claude code
	{
		key = 'D',
		mods = 'CTRL|SHIFT',
		desc = 'Window: dock into another window as a tab',
		action = wezterm.action_callback(function(window, pane)
			local pane_id = tostring(pane:pane_id())
			pick_target(window, pane, 'window', function(window_id)
				wezterm_cli { 'move-pane-to-new-tab', '--window-id', window_id, '--pane-id', pane_id }
			end)
		end),
	},

	-- ctrl+shift+s joins the current pane into another tab as a split on the
	-- right, the reverse of ctrl+shift+b. a tab left with no panes closes
	{
		key = 'S',
		mods = 'CTRL|SHIFT',
		desc = 'Tab: join into another tab as a split',
		action = wezterm.action_callback(function(window, pane)
			local pane_id = tostring(pane:pane_id())
			pick_target(window, pane, 'tab', function(target_pane_id)
				wezterm_cli { 'split-pane', '--pane-id', target_pane_id, '--right', '--move-pane-id', pane_id }
			end)
		end),
	},

	-- alt+c picks a color for the current tab (see Tab Colors above)
	{
		key = 'c',
		mods = 'ALT',
		desc = 'Tab: color',
		action = wezterm.action.InputSelector {
			title = 'Tab color',
			choices = tab_color_choices,
			action = wezterm.action_callback(function(window, _, id)
				-- id is nil when the selector is cancelled with escape
				if not id then
					return
				end
				local key = tab_color_key(window:active_tab():tab_id())
				if id == 'none' then
					wezterm.GLOBAL[key] = nil
				else
					wezterm.GLOBAL[key] = id
				end
				-- the tab bar was already redrawn when the selector closed, before
				-- this ran. a status change rebuilds it, but only when the text
				-- differs, so flip the unused right status to ' ' and back
				window:set_right_status(' ')
				window:set_right_status('')
			end),
		},
	},

	-- vim-style alt+h/l cycles to the previous/next tab, wrapping at the ends
	-- the label also lists wezterm's default ctrl+tab / ctrl+shift+tab, which do
	-- the same thing, so the cheat sheet shows both on one row
	{ key = 'h', mods = 'ALT', action = wezterm.action.ActivateTabRelative(-1), desc = 'Tab: previous', label = 'Alt+H / Ctrl+Shift+Tab' },
	{ key = 'l', mods = 'ALT', action = wezterm.action.ActivateTabRelative(1), desc = 'Tab: next', label = 'Alt+L / Ctrl+Tab' },

	-- ctrl+alt+h/l shifts the current tab one place left/right in the tab bar
	{ key = 'h', mods = 'CTRL|ALT', action = wezterm.action.MoveTabRelative(-1), desc = 'Tab: move left' },
	{ key = 'l', mods = 'CTRL|ALT', action = wezterm.action.MoveTabRelative(1), desc = 'Tab: move right' },

	-- the rest of the tab actions share the alt family with alt+h/l above
	{ key = 't', mods = 'ALT', action = wezterm.action.SpawnTab 'CurrentPaneDomain', desc = 'Tab: new' },
	{ key = 'w', mods = 'ALT', action = wezterm.action.CloseCurrentTab { confirm = true }, desc = 'Tab: close' },

	-- like win+down on windows. takes over the default ctrl+shift+down pane
	-- focus, which ctrl+shift+j still covers
	{ key = 'DownArrow', mods = 'CTRL|SHIFT', action = wezterm.action.Hide, desc = 'Window: minimize' },
}

-- -- Cheat Sheet --

-- wezterm defaults worth remembering. listed for the cheat sheet only; they
-- are already bound, so `label` spells out the keys instead of key/mods
local builtin_keys = {
	{ label = 'Ctrl+Shift+Z', action = wezterm.action.TogglePaneZoomState, desc = 'Pane: zoom in/out (fill the tab)' },
	{ label = 'Ctrl+Shift+N', action = wezterm.action.SpawnWindow, desc = 'Window: new' },
	{ label = 'Ctrl+Shift+F', action = wezterm.action.Search 'CurrentSelectionOrEmptyString', desc = 'Terminal: search scrollback' },
	{ label = 'Ctrl+Shift+X', action = wezterm.action.ActivateCopyMode, desc = 'Terminal: copy mode (select with keys)' },
	{ label = 'Ctrl+Shift+Space', action = wezterm.action.QuickSelect, desc = 'Terminal: quick select (urls, hashes, paths)' },
	{ label = 'Ctrl+Shift+P', action = wezterm.action.ActivateCommandPalette, desc = 'Terminal: command palette' },
	{ label = 'Ctrl+Shift+R', action = wezterm.action.ReloadConfiguration, desc = 'Terminal: reload config' },
}

-- 'CTRL|SHIFT' + 'E' -> 'Ctrl+Shift+E'
local function key_label(k)
	if k.label then
		return k.label
	end
	local parts = {}
	for _, mod in ipairs { 'CTRL', 'ALT', 'SHIFT' } do
		if (k.mods or ''):find(mod) then
			table.insert(parts, mod:sub(1, 1) .. mod:sub(2):lower())
		end
	end
	table.insert(parts, #k.key == 1 and k.key:upper() or k.key)
	return table.concat(parts, '+')
end

local cheat_entries = {}
for _, list in ipairs { keys, builtin_keys } do
	for _, k in ipairs(list) do
		table.insert(cheat_entries, { label = key_label(k), desc = k.desc, action = k.action })
	end
end
table.sort(cheat_entries, function(a, b)
	return a.desc < b.desc
end)

-- the selector has no real headers, so each group gets a plain entry that
-- does nothing when picked. rows drop the 'Group: ' prefix the header now shows
local cheat_choices = {}
local current_group
for i, e in ipairs(cheat_entries) do
	local group, rest = e.desc:match '^(.-):%s*(.*)$'
	if group ~= current_group then
		current_group = group
		-- rows are single-line, so spacing between groups is a blank entry
		if #cheat_choices > 0 then
			table.insert(cheat_choices, { id = 'header', label = ' ' })
		end
		table.insert(cheat_choices, {
			id = 'header',
			label = wezterm.format {
				{ Attribute = { Intensity = 'Bold' } },
				{ Foreground = { AnsiColor = 'Yellow' } },
				{ Text = group },
			},
		})
	end
	table.insert(cheat_choices, {
		id = tostring(i),
		label = wezterm.format {
			{ Foreground = { AnsiColor = 'Aqua' } },
			{ Text = '  ' .. string.format('%-24s', e.label) },
			'ResetAttributes',
			{ Text = rest },
		},
	})
end

-- ctrl+shift+/ (ctrl+?) opens the cheat sheet. type to filter, enter runs the
-- highlighted entry, escape closes it. phys:Slash matches the physical key so
-- shift turning / into ? can't make the binding miss
table.insert(keys, {
	key = 'phys:Slash',
	mods = 'CTRL|SHIFT',
	action = wezterm.action.InputSelector {
		title = 'Key bindings',
		choices = cheat_choices,
		fuzzy = true,
		fuzzy_description = 'Type to filter, Enter runs it, Esc closes: ',
		action = wezterm.action_callback(function(window, pane, id)
			if id and id ~= 'header' then
				window:perform_action(cheat_entries[tonumber(id)].action, pane)
			end
		end),
	},
	desc = 'Terminal: key bindings cheat sheet',
	label = 'Ctrl+Shift+/',
})

-- the custom bindings also show up by name in the command palette. entries
-- added here get no key column, so the key goes in the name
wezterm.on('augment-command-palette', function()
	local commands = {}
	for _, k in ipairs(keys) do
		if k.desc then
			table.insert(commands, { brief = k.desc .. '  (' .. key_label(k) .. ')', action = k.action })
		end
	end
	return commands
end)

-- wezterm defaults for actions that have their own key above. turned off so
-- each action has exactly one key: stray presses do nothing, and the command
-- palette shows the key from this file instead of a default. added after the
-- cheat sheet and palette are built since these have no desc
for _, d in ipairs {
	{ 'T', 'CTRL|SHIFT' }, { 't', 'SUPER' }, -- new tab (alt+t)
	{ 'W', 'CTRL|SHIFT' }, { 'w', 'SUPER' }, -- close tab (alt+w)
	{ 'M', 'CTRL|SHIFT' }, { 'm', 'SUPER' }, -- minimize (ctrl+shift+down)
	{ 'PageUp', 'CTRL|SHIFT' }, { 'PageDown', 'CTRL|SHIFT' }, -- move tab (ctrl+alt+h/l)
	-- previous/next tab (alt+h/l). ctrl+tab / ctrl+shift+tab stay on, like chrome
	{ 'PageUp', 'CTRL' }, { 'PageDown', 'CTRL' },
	{ '[', 'SUPER|SHIFT' }, { ']', 'SUPER|SHIFT' }, { '{', 'SUPER' }, { '}', 'SUPER' },
	{ '{', 'SUPER|SHIFT' }, { '}', 'SUPER|SHIFT' },
	-- pane focus (ctrl+shift+h/j/k/l; the down arrow is minimize now)
	{ 'LeftArrow', 'CTRL|SHIFT' }, { 'RightArrow', 'CTRL|SHIFT' }, { 'UpArrow', 'CTRL|SHIFT' },
	-- splits (ctrl+alt+v/s)
	{ '"', 'CTRL|ALT' }, { '"', 'CTRL|SHIFT|ALT' }, { "'", 'CTRL|SHIFT|ALT' },
	{ '%', 'CTRL|ALT' }, { '%', 'CTRL|SHIFT|ALT' }, { '5', 'CTRL|SHIFT|ALT' },
} do
	table.insert(keys, { key = d[1], mods = d[2], action = wezterm.action.DisableDefaultAssignment })
end

-- wezterm rejects unknown fields on a key entry, so copy without desc
config.keys = {}
for _, k in ipairs(keys) do
	table.insert(config.keys, { key = k.key, mods = k.mods, action = k.action })
end

return config
