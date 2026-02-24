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

	-- Build terminal config for a given position
	local function terminal_config_for(position)
		local pos_config = position_configs[position]
		return {
			split_side = (position == "left" or position == "right") and position or "right",
			split_width_percentage = pos_config.width > 0 and pos_config.width or 0.40,
			snacks_win_opts = pos_config,
		}
	end

	-- Initial setup (only called once — avoids server restart)
	local initial_terminal = terminal_config_for(_G.claudecode_position)
	require("claudecode").setup(vim.tbl_deep_extend("force", default_config, {
		terminal = initial_terminal,
	}))

	-- Absolute split commands (layout-independent positioning)
	local split_for = {
		left = "topleft vsplit",
		right = "botright vsplit",
		top = "topleft split",
		bottom = "botright split",
	}

	-- Terminal buffer we've taken over management of (after a position switch)
	local managed_buf = nil

	-- Find the claude terminal buffer
	local function find_claude_term_buf()
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
				local name = vim.api.nvim_buf_get_name(buf)
				if name:match("claude") then
					return buf
				end
			end
		end
		return nil
	end

	-- Find the window displaying a buffer (nil if hidden)
	local function find_buf_win(buf)
		if not buf or not vim.api.nvim_buf_is_valid(buf) then return nil end
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if vim.api.nvim_win_get_buf(win) == buf then
				return win
			end
		end
		return nil
	end

	-- Check if we're managing the terminal ourselves
	local function is_managed()
		if managed_buf and vim.api.nvim_buf_is_valid(managed_buf) then
			return true
		end
		managed_buf = nil
		return false
	end

	-- Resize a window for the current position
	local function resize_for_position(win)
		local pos_config = position_configs[_G.claudecode_position]
		if _G.claudecode_position == "left" or _G.claudecode_position == "right" then
			local width = math.floor(vim.o.columns * (pos_config.width > 0 and pos_config.width or 0.40))
			vim.api.nvim_win_set_width(win, width)
		else
			local height = math.floor(vim.o.lines * (pos_config.height > 0 and pos_config.height or 0.35))
			vim.api.nvim_win_set_height(win, height)
		end
	end

	-- Show the managed terminal in the current position
	local function show_managed()
		vim.cmd(split_for[_G.claudecode_position])
		vim.api.nvim_win_set_buf(0, managed_buf)
		resize_for_position(0)
	end

	-- Toggle the managed terminal (show/hide)
	local function managed_toggle()
		local win = find_buf_win(managed_buf)
		if win then
			-- Visible → hide (just close window, keep buffer/process)
			vim.api.nvim_win_close(win, false)
		else
			-- Hidden → show in current position
			show_managed()
		end
	end

	-- Switch terminal position at runtime by moving the existing window
	local function switch_position(position)
		local pos_config = position_configs[position]
		if not pos_config then return end
		_G.claudecode_position = position

		-- Update terminal defaults for future terminals
		local term = require("claudecode.terminal")
		local tc = terminal_config_for(position)
		term.defaults.split_side = tc.split_side
		term.defaults.split_width_percentage = tc.split_width_percentage
		term.defaults.snacks_win_opts = tc.snacks_win_opts

		-- Find the terminal buffer (check managed first, then search)
		local term_buf = is_managed() and managed_buf or find_claude_term_buf()
		if not term_buf then
			-- No terminal exists yet, open one via plugin
			vim.cmd("ClaudeCode")
			return
		end

		-- Take over management of this terminal
		managed_buf = term_buf

		-- Close the current window if visible
		local term_win = find_buf_win(term_buf)
		local prev_win = vim.api.nvim_get_current_win()
		if term_win then
			vim.api.nvim_win_close(term_win, false)
		end

		-- Open in new position
		show_managed()

		-- Return focus to previous window
		if vim.api.nvim_win_is_valid(prev_win) then
			vim.api.nvim_set_current_win(prev_win)
		end
	end

	-- Override ClaudeCode toggle to handle managed terminals
	vim.api.nvim_create_user_command("ClaudeCode", function(opts)
		if is_managed() then
			managed_toggle()
		else
			-- Default plugin behavior
			local cmd_args = opts.args ~= "" and opts.args or nil
			require("claudecode.terminal").simple_toggle({}, cmd_args)
		end
	end, { nargs = "*", force = true, desc = "Toggle Claude Code terminal" })

	-- Override ClaudeCodeClose to handle managed terminals
	vim.api.nvim_create_user_command("ClaudeCodeClose", function()
		if is_managed() then
			local win = find_buf_win(managed_buf)
			if win then
				vim.api.nvim_win_close(win, false)
			end
		else
			require("claudecode.terminal").close()
		end
	end, { force = true, desc = "Close Claude Code terminal" })

	-- Override ClaudeCodeFocus to handle managed terminals
	vim.api.nvim_create_user_command("ClaudeCodeFocus", function()
		if is_managed() then
			local win = find_buf_win(managed_buf)
			if win then
				if vim.api.nvim_get_current_win() == win then
					vim.api.nvim_win_close(win, false)
				else
					vim.api.nvim_set_current_win(win)
				end
			else
				show_managed()
			end
		else
			require("claudecode.terminal").focus_toggle({})
		end
	end, { force = true, desc = "Focus/toggle Claude Code terminal" })

	-- Create commands for position switching
	local positions = { "left", "right", "top", "bottom" }
	for _, pos in ipairs(positions) do
		vim.api.nvim_create_user_command("ClaudeCode" .. pos:gsub("^%l", string.upper), function()
			switch_position(pos)
		end, { desc = "Open Claude Code on " .. pos })
	end

	-- Expose for keybindings
	_G.claudecode_set_position = switch_position
end
