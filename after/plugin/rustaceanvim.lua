local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "rustaceanvim") then
	-- Get codelldb paths from Mason for DAP integration
	local mason_path = vim.fn.stdpath("data") .. "/mason/packages/"
	local codelldb_path = mason_path .. "codelldb/extension/adapter/codelldb"
	local liblldb_path = mason_path .. "codelldb/extension/lldb/lib/liblldb.so"

	-- Check if codelldb is installed
	local codelldb_installed = vim.fn.filereadable(codelldb_path) == 1

	vim.g.rustaceanvim = {
		-- Plugin configuration
		tools = {
			-- How to execute terminal commands
			executor = require("rustaceanvim.executors").termopen,
			-- Automatically set inlay hints (using native Neovim 0.10+ feature)
			inlay_hints = {
				auto = true,
			},
			-- Hover actions
			hover_actions = {
				replace_builtin_hover = true,
			},
			-- Float window configuration
			float_win_config = {
				border = "rounded",
			},
		},

		-- LSP configuration (passed to rust-analyzer)
		server = {
			on_attach = function(_, bufnr)
				-- Rust-specific keybindings
				local opts = { buffer = bufnr, silent = true }

				-- Hover actions (replaces default hover with rust-specific actions)
				vim.keymap.set("n", "<C-space>", function()
					vim.cmd.RustLsp({ "hover", "actions" })
				end, vim.tbl_extend("force", opts, { desc = "Rust hover actions" }))

				-- Code action groups
				vim.keymap.set("n", "<leader>ca", function()
					vim.cmd.RustLsp("codeAction")
				end, vim.tbl_extend("force", opts, { desc = "Rust code actions" }))

				-- Runnables
				vim.keymap.set("n", "<leader>rr", function()
					vim.cmd.RustLsp("runnables")
				end, vim.tbl_extend("force", opts, { desc = "Rust runnables" }))

				-- Debuggables
				vim.keymap.set("n", "<leader>rd", function()
					vim.cmd.RustLsp("debuggables")
				end, vim.tbl_extend("force", opts, { desc = "Rust debuggables" }))

				-- Expand macro
				vim.keymap.set("n", "<leader>rm", function()
					vim.cmd.RustLsp("expandMacro")
				end, vim.tbl_extend("force", opts, { desc = "Expand macro" }))

				-- Cargo run
				vim.keymap.set("n", "<leader>rc", function()
					vim.cmd.RustLsp("run")
				end, vim.tbl_extend("force", opts, { desc = "Cargo run" }))

				-- Open Cargo.toml
				vim.keymap.set("n", "<leader>ro", function()
					vim.cmd.RustLsp("openCargo")
				end, vim.tbl_extend("force", opts, { desc = "Open Cargo.toml" }))

				-- Parent module
				vim.keymap.set("n", "<leader>rp", function()
					vim.cmd.RustLsp("parentModule")
				end, vim.tbl_extend("force", opts, { desc = "Go to parent module" }))

				-- Join lines (Rust-aware)
				vim.keymap.set("n", "J", function()
					vim.cmd.RustLsp("joinLines")
				end, vim.tbl_extend("force", opts, { desc = "Join lines (Rust)" }))

				-- Explain error
				vim.keymap.set("n", "<leader>re", function()
					vim.cmd.RustLsp("explainError")
				end, vim.tbl_extend("force", opts, { desc = "Explain error" }))

				-- Render diagnostics
				vim.keymap.set("n", "<leader>rD", function()
					vim.cmd.RustLsp("renderDiagnostic")
				end, vim.tbl_extend("force", opts, { desc = "Render diagnostic" }))
			end,
			default_settings = {
				["rust-analyzer"] = {
					-- Enable clippy on save
					checkOnSave = {
						command = "clippy",
					},
					-- Inlay hints configuration
					inlayHints = {
						bindingModeHints = { enable = true },
						closingBraceHints = { enable = true, minLines = 25 },
						closureReturnTypeHints = { enable = "with_block" },
						lifetimeElisionHints = { enable = "never", useParameterNames = false },
						maxLength = 25,
						parameterHints = { enable = true },
						reborrowHints = { enable = "never" },
						renderColons = true,
						typeHints = {
							enable = true,
							hideClosureInitialization = false,
							hideNamedConstructor = false,
						},
					},
					-- Cargo configuration
					cargo = {
						allFeatures = true,
						loadOutDirsFromCheck = true,
					},
					-- Proc macro support
					procMacro = {
						enable = true,
					},
				},
			},
		},

		-- DAP configuration
		dap = codelldb_installed and {
			adapter = require("rustaceanvim.config").get_codelldb_adapter(codelldb_path, liblldb_path),
		} or nil,
	}
end
