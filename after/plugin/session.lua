local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "session_manager") then
	require("persisted").setup({
		autostart = true, -- auto-save session on exit
		autoload = false, -- don't auto-load; dashboard is the entry point
		use_git_branch = true, -- separate sessions per git branch
		follow_cwd = true, -- update session file when CWD changes
		ignored_dirs = {
			{ vim.fn.expand("~"), exact = true },
			{ "/tmp", exact = true },
		},
		should_save = function()
			-- Don't save sessions for dashboard, empty buffers, or special buftype-only layouts
			local dominated_fts = { "alpha", "neo-tree", "" }
			if vim.tbl_contains(dominated_fts, vim.bo.filetype) then return false end
			-- Must have at least one normal buffer to justify saving
			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" and vim.bo[buf].buflisted then
					return true
				end
			end
			return false
		end,
	})

	-- Notify on session restore so the user knows it worked
	vim.api.nvim_create_autocmd("User", {
		pattern = "PersistedLoadPost",
		callback = function()
			local cwd = vim.fn.getcwd()
			local project = vim.fn.fnamemodify(cwd, ":t")
			-- Try to show branch name
			local branch = vim.fn.system("git -C " .. vim.fn.shellescape(cwd) .. " branch --show-current 2>/dev/null")
			branch = vim.trim(branch)
			local msg = project
			if branch ~= "" then
				msg = project .. " @ " .. branch
			end
			utils.notify_info(msg .. " restored", "Session")
		end,
	})

	-- Auto-resume session recording on first file write after <leader>sn
	-- If recording was stopped (fresh workspace) and the user saves a file,
	-- they clearly want to keep working — resume so the layout saves on exit
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = vim.api.nvim_create_augroup("session_auto_resume", { clear = true }),
		callback = function()
			if vim.bo.buftype ~= "" then return end
			if not vim.g.persisting then
				require("persisted").start()
				utils.notify_info("Session recording resumed", "Session")
			end
		end,
	})
end
