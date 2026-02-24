local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "telescope") then
	-- Colorscheme registry: all available schemes with transparency metadata
	local colorschemes = {
		{ name = "tokyonight-night",      family = "tokyonight", module = "tokyonight",  transparent_key = "transparent" },
		{ name = "tokyonight-storm",      family = "tokyonight", module = "tokyonight",  transparent_key = "transparent" },
		{ name = "tokyonight-day",        family = "tokyonight", module = "tokyonight",  transparent_key = "transparent" },
		{ name = "catppuccin-mocha",      family = "catppuccin",  module = "catppuccin",  transparent_key = "transparent_background" },
		{ name = "catppuccin-frappe",     family = "catppuccin",  module = "catppuccin",  transparent_key = "transparent_background" },
		{ name = "catppuccin-macchiato",  family = "catppuccin",  module = "catppuccin",  transparent_key = "transparent_background" },
		{ name = "catppuccin-latte",      family = "catppuccin",  module = "catppuccin",  transparent_key = "transparent_background" },
		{ name = "nightfox",              family = "nightfox",    module = "nightfox",    transparent_key = "options.transparent" },
		{ name = "duskfox",               family = "nightfox",    module = "nightfox",    transparent_key = "options.transparent" },
		{ name = "dayfox",                family = "nightfox",    module = "nightfox",    transparent_key = "options.transparent" },
		{ name = "terafox",               family = "nightfox",    module = "nightfox",    transparent_key = "options.transparent" },
		{ name = "carbonfox",             family = "nightfox",    module = "nightfox",    transparent_key = "options.transparent" },
		{ name = "monokai-pro",           family = "monokai-pro", module = "monokai-pro", transparent_key = "transparent_background" },
		{ name = "monokai-pro-machine",   family = "monokai-pro", module = "monokai-pro", transparent_key = "transparent_background" },
		{ name = "monokai-pro-octagon",   family = "monokai-pro", module = "monokai-pro", transparent_key = "transparent_background" },
		{ name = "monokai-pro-ristretto", family = "monokai-pro", module = "monokai-pro", transparent_key = "transparent_background" },
		{ name = "monokai-pro-spectrum",  family = "monokai-pro", module = "monokai-pro", transparent_key = "transparent_background" },
		{ name = "astrodark",             family = "astrotheme",  module = "astrotheme",  transparent_key = "style.transparent" },
		{ name = "astromars",             family = "astrotheme",  module = "astrotheme",  transparent_key = "style.transparent" },
		{ name = "astrolight",            family = "astrotheme",  module = "astrotheme",  transparent_key = "style.transparent" },
		{ name = "default",               family = nil,           module = nil,           transparent_key = nil },
	}

	-- Build transparency config table from dotted key (e.g. "options.transparent" -> { options = { transparent = val } })
	local function build_transparent_config(key, value)
		local parts = vim.split(key, ".", { plain = true })
		local config = {}
		local current = config
		for i = 1, #parts - 1 do
			current[parts[i]] = {}
			current = current[parts[i]]
		end
		current[parts[#parts]] = value
		return config
	end

	-- Set transparency for a theme module
	local function set_transparency(entry, enabled)
		if not entry.module or not entry.transparent_key then return end
		local ok, mod = pcall(require, entry.module)
		if ok and mod.setup then
			mod.setup(build_transparent_config(entry.transparent_key, enabled))
		end
	end

	-- Persist colorscheme choice to user/config.lua
	local function persist_colorscheme(scheme_name)
		local config_path = vim.fn.stdpath("config") .. "/lua/user/config.lua"
		local lines = vim.fn.readfile(config_path)
		if not lines or #lines == 0 then return end

		local pattern = 'utils%.colors%(".-"%)' -- matches: utils.colors("anything")
		local replacement = 'utils.colors("' .. scheme_name .. '")'
		local found = false

		for i, line in ipairs(lines) do
			-- Only replace the active (uncommented) utils.colors line
			if line:match("^%s*utils%.colors%(") and not line:match("^%s*%-%-") then
				lines[i] = line:gsub(pattern, replacement)
				found = true
				break
			end
		end

		if found then
			vim.fn.writefile(lines, config_path)
		end
	end

	-- Apply a colorscheme entry with current transparency setting
	local function apply_entry(entry, transparent)
		if entry and entry.module then
			set_transparency(entry, transparent)
		end
		pcall(vim.cmd.colorscheme, entry and entry.name or "default")
	end

	-- The picker
	_G.lush_colors_pick = function()
		local actions = require("telescope.actions")
		local action_state = require("telescope.actions.state")
		local pickers = require("telescope.pickers")
		local finders = require("telescope.finders")
		local conf = require("telescope.config").values

		local original_scheme = vim.g.colors_name or "default"
		local transparent = false
		local need_restore = true

		local picker = pickers.new({}, {
			prompt_title = "Colorscheme",
			finder = finders.new_table({
				results = colorschemes,
				entry_maker = function(entry)
					local display = entry.name
					if entry.family then
						display = entry.name .. "  (" .. entry.family .. ")"
					end
					return {
						display = display,
						value = entry,
						ordinal = entry.name .. " " .. (entry.family or ""),
					}
				end,
			}),
			previewer = false,
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				-- Toggle transparency with <C-t>
				local function toggle_transparency()
					transparent = not transparent
					local title = transparent and "Colorscheme [transparent]" or "Colorscheme"
					action_state.get_current_picker(prompt_bufnr).prompt_border:change_title(title)
					local selection = action_state.get_selected_entry()
					if selection then
						apply_entry(selection.value, transparent)
					end
				end
				map("i", "<C-t>", toggle_transparency)
				map("n", "<C-t>", toggle_transparency)

				-- Confirm selection: apply + persist
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					need_restore = false
					actions.close(prompt_bufnr)
					if not selection then return end

					apply_entry(selection.value, transparent)
					persist_colorscheme(selection.value.name)
					utils.notify_info(selection.value.name .. (transparent and " (transparent)" or ""), "Colorscheme")
				end)

				return true
			end,
		})

		-- Override set_selection to live-preview on every selection change
		-- (same technique as telescope's built-in colorscheme picker)
		local original_set_selection = picker.set_selection
		picker.set_selection = function(self, row)
			original_set_selection(self, row)
			local selection = action_state.get_selected_entry()
			if selection then
				apply_entry(selection.value, transparent)
			end
		end

		-- Override close_windows to restore original colorscheme on cancel
		local original_close_windows = picker.close_windows
		picker.close_windows = function(status)
			original_close_windows(status)
			if need_restore then
				pcall(vim.cmd.colorscheme, original_scheme)
			end
		end

		picker:find()
	end

	-- User command
	vim.api.nvim_create_user_command("LushColors", function()
		lush_colors_pick()
	end, { desc = "Pick colorscheme with live preview and persistence" })
end
