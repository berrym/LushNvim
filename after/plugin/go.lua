-- Go LSP configuration
-- gopls handles formatting (gofumpt), imports, and linting (staticcheck)
local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "lsp") then
	-- Go-specific keybindings (only in Go buffers)
	vim.api.nvim_create_autocmd("FileType", {
		pattern = { "go", "gomod", "gowork", "gotmpl" },
		callback = function(args)
			local opts = { buffer = args.buf, silent = true }

			-- Organize imports
			vim.keymap.set("n", "<leader>Gi", function()
				vim.lsp.buf.code_action({
					apply = true,
					context = {
						only = { "source.organizeImports" },
						diagnostics = {},
					},
				})
			end, vim.tbl_extend("force", opts, { desc = "Organize imports" }))

			-- Format buffer (gopls with gofumpt)
			vim.keymap.set("n", "<leader>Gf", function()
				vim.lsp.buf.format({ async = true })
			end, vim.tbl_extend("force", opts, { desc = "Format (gofumpt)" }))

			-- Run go mod tidy via codelens
			vim.keymap.set("n", "<leader>Gt", function()
				vim.lsp.codelens.run()
			end, vim.tbl_extend("force", opts, { desc = "Run codelens (tidy/test/etc)" }))

			-- Add struct tags (requires gomodifytags via null-ls)
			vim.keymap.set("n", "<leader>Ga", function()
				vim.lsp.buf.code_action({
					apply = true,
					context = {
						only = { "source.addTags" },
						diagnostics = {},
					},
				})
			end, vim.tbl_extend("force", opts, { desc = "Add struct tags" }))

			-- Remove struct tags
			vim.keymap.set("n", "<leader>GR", function()
				vim.lsp.buf.code_action({
					apply = true,
					context = {
						only = { "source.removeTags" },
						diagnostics = {},
					},
				})
			end, vim.tbl_extend("force", opts, { desc = "Remove struct tags" }))

			-- Fill struct (gopls code action)
			vim.keymap.set("n", "<leader>Gs", function()
				vim.lsp.buf.code_action({
					apply = true,
					context = {
						only = { "refactor.rewrite.fillStruct" },
						diagnostics = {},
					},
				})
			end, vim.tbl_extend("force", opts, { desc = "Fill struct" }))

			-- Generate (interface implementation, etc)
			vim.keymap.set("n", "<leader>Gg", function()
				vim.lsp.buf.code_action({
					apply = true,
					context = {
						only = { "source.generate" },
						diagnostics = {},
					},
				})
			end, vim.tbl_extend("force", opts, { desc = "Generate" }))

			-- Refresh codelenses
			vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
				buffer = args.buf,
				callback = function()
					pcall(vim.lsp.codelens.refresh)
				end,
			})
		end,
	})
end

-- ════════════════════════════════════════════════════════════════════════════
-- Go Debug Configuration (nvim-dap-go)
-- ════════════════════════════════════════════════════════════════════════════
if utils.enabled(group, "dap") and utils.enabled(group, "dap_go") then
	local ok_dap_go, dap_go = pcall(require, "dap-go")
	if ok_dap_go then
		dap_go.setup({
			delve = {
				path = vim.fn.stdpath("data") .. "/mason/bin/dlv",
				initialize_timeout_sec = 20,
				port = "${port}",
			},
		})

		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "go", "gomod" },
			callback = function(args)
				local opts = { buffer = args.buf, silent = true }

				vim.keymap.set("n", "<leader>Gd", function()
					require("dap").continue()
				end, vim.tbl_extend("force", opts, { desc = "Debug file" }))

				vim.keymap.set("n", "<leader>GT", function()
					dap_go.debug_test()
				end, vim.tbl_extend("force", opts, { desc = "Debug test" }))

				vim.keymap.set("n", "<leader>GL", function()
					dap_go.debug_last_test()
				end, vim.tbl_extend("force", opts, { desc = "Debug last test" }))
			end,
		})
	end
end
