local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "claudecode") then
	-- Default configuration
	local default_config = {
		terminal_cmd = "claude",
		auto_close = true,
		track_selection = true,
		auto_start = true,
		log_level = "warn",
		diff_provider = "snacks",
		diff_opts = {
			auto_close_on_accept = true,
			layout = "vertical",
		},
		terminal = {
			show_native_term_exit_tip = false,
			split_side = "right",
			split_width_percentage = 0.40,
		},
	}

	-- Current position (can be changed at runtime)
	_G.claudecode_position = _G.claudecode_position or "right"

	-- Position configs for snacks_win_opts (bypasses plugin validation for top/bottom)
	local position_configs = {
		left = { position = "left", width = 0.40, height = 0 },
		right = { position = "right", width = 0.40, height = 0 },
		top = { position = "top", height = 0.35, width = 0 },
		bottom = { position = "bottom", height = 0.35, width = 0 },
	}

	-- Function to apply config with current position
	local function apply_config(position)
		local pos_config = position_configs[position]
		if not pos_config then
			vim.notify("Invalid position: " .. tostring(position), vim.log.levels.WARN)
			position = "right"
			pos_config = position_configs.right
		end
		_G.claudecode_position = position

		-- For left/right, use native split_side; for top/bottom, use snacks_win_opts
		local terminal_config = {
			split_side = (position == "left" or position == "right") and position or "right",
			split_width_percentage = pos_config.width > 0 and pos_config.width or 0.40,
			snacks_win_opts = pos_config,
		}

		local config = vim.tbl_deep_extend("force", default_config, {
			terminal = terminal_config,
		})
		require("claudecode").setup(config)
	end

	-- Initial setup with current position
	apply_config(_G.claudecode_position)

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
