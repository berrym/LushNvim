local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "claudecode") then
	-- Default configuration
	local default_config = {
		terminal_cmd = "claude",
		split_side = "bottom", -- "left", "right", "top", "bottom"
		split_height_percentage = 0.35,
		split_width_percentage = 0.40,
		auto_close = true,
		track_selection = true,
		auto_start = true,
		log_level = "warn",
		diff_opts = {
			auto_close_on_accept = true,
			vertical_split = true,
		},
	}

	-- Current position (can be changed at runtime)
	_G.claudecode_position = _G.claudecode_position or "bottom"

	-- Function to apply config with current position
	local function apply_config(position)
		_G.claudecode_position = position or _G.claudecode_position
		local config = vim.tbl_deep_extend("force", default_config, {
			split_side = _G.claudecode_position,
		})
		require("claudecode").setup(config)
	end

	-- Initial setup
	apply_config()

	-- Create commands for position switching
	local positions = { "left", "right", "top", "bottom" }
	for _, pos in ipairs(positions) do
		vim.api.nvim_create_user_command("ClaudeCode" .. pos:gsub("^%l", string.upper), function()
			-- Close existing terminal if open
			pcall(vim.cmd, "ClaudeCodeClose")
			-- Apply new position
			apply_config(pos)
			-- Reopen
			vim.cmd("ClaudeCode")
		end, { desc = "Open Claude Code on " .. pos })
	end

	-- Expose for keybindings
	_G.claudecode_set_position = function(pos)
		pcall(vim.cmd, "ClaudeCodeClose")
		apply_config(pos)
		vim.cmd("ClaudeCode")
	end
end
