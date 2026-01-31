-- C/C++ LSP configuration
-- clangd handles LSP, clang-tidy (linting), and clang-format (formatting)
local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "lsp") then
	-- C/C++ specific keybindings (only in C/C++ buffers)
	vim.api.nvim_create_autocmd("FileType", {
		pattern = { "c", "cpp", "objc", "objcpp", "cuda" },
		callback = function(args)
			local opts = { buffer = args.buf, silent = true }

			-- Switch between header and source file
			vim.keymap.set("n", "<leader>Cs", function()
				local params = { uri = vim.uri_from_bufnr(0) }
				vim.lsp.buf_request(0, "textDocument/switchSourceHeader", params, function(err, result)
					if err then
						vim.notify("Error switching header/source: " .. tostring(err), vim.log.levels.ERROR)
						return
					end
					if result then
						vim.cmd.edit(vim.uri_to_fname(result))
					else
						vim.notify("No corresponding header/source file found", vim.log.levels.WARN)
					end
				end)
			end, vim.tbl_extend("force", opts, { desc = "Switch header/source" }))

			-- Format buffer (clang-format via null-ls or clangd)
			vim.keymap.set("n", "<leader>Cf", function()
				vim.lsp.buf.format({ async = true })
			end, vim.tbl_extend("force", opts, { desc = "Format (clang-format)" }))

			-- Symbol info (clangd extension)
			vim.keymap.set("n", "<leader>Ci", function()
				local params = vim.lsp.util.make_position_params()
				vim.lsp.buf_request(0, "textDocument/symbolInfo", params, function(err, result)
					if err or not result or #result == 0 then
						vim.notify("No symbol info available", vim.log.levels.WARN)
						return
					end
					local info = result[1]
					local msg = string.format("Name: %s\nContainer: %s\nUSR: %s",
						info.name or "N/A",
						info.containerName or "N/A",
						info.usr or "N/A")
					vim.notify(msg, vim.log.levels.INFO, { title = "Symbol Info" })
				end)
			end, vim.tbl_extend("force", opts, { desc = "Symbol info" }))

			-- Type hierarchy (incoming)
			vim.keymap.set("n", "<leader>Ch", function()
				vim.lsp.buf.typehierarchy("supertypes")
			end, vim.tbl_extend("force", opts, { desc = "Type hierarchy (supertypes)" }))

			-- Type hierarchy (outgoing)
			vim.keymap.set("n", "<leader>CH", function()
				vim.lsp.buf.typehierarchy("subtypes")
			end, vim.tbl_extend("force", opts, { desc = "Type hierarchy (subtypes)" }))

			-- Toggle inlay hints
			vim.keymap.set("n", "<leader>Ct", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = args.buf }), { bufnr = args.buf })
			end, vim.tbl_extend("force", opts, { desc = "Toggle inlay hints" }))

			-- Compile (if Makefile exists)
			vim.keymap.set("n", "<leader>Cc", function()
				if vim.fn.filereadable("Makefile") == 1 or vim.fn.filereadable("makefile") == 1 then
					vim.cmd("make")
				elseif vim.fn.filereadable("CMakeLists.txt") == 1 then
					vim.cmd("!cmake --build build")
				else
					vim.notify("No Makefile or CMakeLists.txt found", vim.log.levels.WARN)
				end
			end, vim.tbl_extend("force", opts, { desc = "Compile (make/cmake)" }))
		end,
	})
end
