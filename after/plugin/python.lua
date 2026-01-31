-- Python LSP configuration
-- Uses basedpyright for type checking/hover and ruff for linting/formatting
local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "lsp") then
	-- Disable ruff's hover in favor of basedpyright (better documentation)
	vim.api.nvim_create_autocmd("LspAttach", {
		group = vim.api.nvim_create_augroup("lsp_attach_disable_ruff_hover", { clear = true }),
		callback = function(args)
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			if client == nil then
				return
			end
			if client.name == "ruff" then
				-- Disable hover in favor of basedpyright
				client.server_capabilities.hoverProvider = false
			end
		end,
		desc = "LSP: Disable ruff hover (basedpyright provides better documentation)",
	})

	-- Python-specific keybindings (only in Python buffers)
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "python",
		callback = function(args)
			local opts = { buffer = args.buf, silent = true }

			-- Organize imports (using ruff)
			vim.keymap.set("n", "<leader>pi", function()
				vim.lsp.buf.code_action({
					apply = true,
					context = {
						only = { "source.organizeImports" },
						diagnostics = {},
					},
				})
			end, vim.tbl_extend("force", opts, { desc = "Organize imports" }))

			-- Fix all auto-fixable issues (using ruff)
			vim.keymap.set("n", "<leader>pf", function()
				vim.lsp.buf.code_action({
					apply = true,
					context = {
						only = { "source.fixAll" },
						diagnostics = {},
					},
				})
			end, vim.tbl_extend("force", opts, { desc = "Fix all (ruff)" }))

			-- Format buffer (using ruff)
			vim.keymap.set("n", "<leader>pF", function()
				vim.lsp.buf.format({ async = true })
			end, vim.tbl_extend("force", opts, { desc = "Format buffer" }))
		end,
	})
end
