local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "diffview") then
	require("diffview").setup({
		enhanced_diff_hl = true,
		default_args = {
			DiffviewOpen = { "--imply-local" },
		},
		view = {
			default = { layout = "diff2_horizontal" },
			merge_tool = { layout = "diff3_mixed", disable_diagnostics = true },
		},
		hooks = {
			diff_buf_read = function()
				vim.opt_local.wrap = false
				vim.opt_local.list = false
			end,
		},
		keymaps = {
			view = {
				{ "n", "q", "<CMD>DiffviewClose<CR>", { desc = "Close diffview" } },
			},
			file_panel = {
				{ "n", "q", "<CMD>DiffviewClose<CR>", { desc = "Close diffview" } },
			},
			file_history_panel = {
				{ "n", "q", "<CMD>DiffviewClose<CR>", { desc = "Close diffview" } },
			},
		},
	})

	-- Auto-refresh diffview file panel when files change externally (e.g. Claude Code)
	local function refresh_diffview()
		pcall(function()
			local lib = require("diffview.lib")
			local view = lib.get_current_view()
			if view then
				view:update_files()
			end
		end)
	end

	vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
		group = vim.api.nvim_create_augroup("diffview_refresh", { clear = true }),
		callback = refresh_diffview,
	})
end
