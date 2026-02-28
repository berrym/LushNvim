-- Language bundle definitions for LushNvim
-- Each bundle specifies defaults that M.languages = { "name" } auto-expands.
-- Users can still override individual tables -- bundles just provide defaults.

local M = {}

M.bundles = {
	c = {
		mason_null_ls = {
			"clangd",
			"clang-format",
			"mesonlsp",
			"checkmake",
			"autotools-language-server",
		},
		mason_dap = { "codelldb" },
		treesitter = { "c", "cpp", "cuda", "cmake", "meson", "make", "ninja", "objdump", "asm" },
		formatting_servers = { "c", "cpp", "objc", "objcpp", "cuda", "proto", "cmake", "meson" },
		lsp_configs = {
			clangd = {
				capabilities = {
					offsetEncoding = { "utf-8", "utf-16" },
					textDocument = {
						completion = {
							editsNearCursor = true,
						},
					},
				},
				cmd = {
					"clangd",
					"--background-index",
					"--clang-tidy",
					"--header-insertion=iwyu",
					"--completion-style=detailed",
					"--function-arg-placeholders",
					"--fallback-style=llvm",
					"--pch-storage=memory",
				},
				filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
				init_options = {
					usePlaceholders = true,
					completeUnimported = true,
					clangdFileStatus = true,
				},
				settings = {
					clangd = {
						InlayHints = {
							Enabled = true,
							ParameterNames = true,
							DeducedTypes = true,
							Designators = true,
						},
					},
				},
			},
		},
		enable_plugins = {},
	},
	python = {
		mason_null_ls = { "basedpyright", "ruff" },
		mason_dap = { "python" },
		treesitter = { "python" },
		formatting_servers = { "python" },
		lsp_configs = {
			basedpyright = {
				cmd = { "basedpyright-langserver", "--stdio" },
				filetypes = { "python" },
				settings = {
					basedpyright = {
						disableOrganizeImports = true,
						analysis = {
							autoSearchPaths = true,
							diagnosticMode = "openFilesOnly",
							useLibraryCodeForTypes = true,
							typeCheckingMode = "standard",
							ignore = { "*" },
						},
					},
				},
			},
			ruff = {
				cmd = { "ruff", "server" },
				filetypes = { "python" },
				init_options = {
					settings = {
						lineLength = 100,
						lint = { select = { "E", "F", "W", "I" } },
						format = { lineLength = 100 },
					},
				},
			},
		},
		enable_plugins = { dap_python = true },
	},
	go = {
		mason_null_ls = { "gopls", "gomodifytags" },
		mason_dap = { "delve" },
		treesitter = { "go", "gomod", "gosum", "gowork", "gotmpl" },
		formatting_servers = { "go" },
		lsp_configs = {
			gopls = {
				cmd = { "gopls" },
				filetypes = { "go", "gomod", "gowork", "gotmpl" },
				settings = {
					gopls = {
						gofumpt = true,
						staticcheck = true,
						analyses = {
							nilness = true,
							unusedparams = true,
							unusedwrite = true,
							useany = true,
							shadow = true,
						},
						completeUnimported = true,
						usePlaceholders = true,
						codelenses = {
							generate = true,
							gc_details = true,
							run_govulncheck = true,
							test = true,
							tidy = true,
							upgrade_dependency = true,
							vendor = true,
						},
						hints = {
							assignVariableTypes = true,
							compositeLiteralFields = true,
							compositeLiteralTypes = true,
							constantValues = true,
							functionTypeParameters = true,
							parameterNames = true,
							rangeVariableTypes = true,
						},
						semanticTokens = true,
						diagnosticsDelay = "500ms",
						diagnosticsTrigger = "Edit",
					},
				},
			},
		},
		enable_plugins = { dap_go = true },
	},
	rust = {
		mason_null_ls = {},
		mason_dap = { "codelldb" },
		treesitter = { "rust", "toml", "ron" },
		formatting_servers = { "rust" },
		lsp_configs = {},
		enable_plugins = { rustaceanvim = true },
	},
	lua = {
		mason_null_ls = { "lua-language-server", "stylua" },
		mason_dap = {},
		treesitter = { "lua", "luap", "luadoc", "vim", "vimdoc" },
		formatting_servers = { "lua" },
		lsp_configs = {
			lua_ls = {
				cmd = { "lua-language-server" },
				filetypes = { "lua" },
				settings = {
					Lua = {
						diagnostics = {
							disable = { "missing-fields" },
							globals = { "vim" },
						},
						hint = { enable = true },
					},
				},
				log_level = 2,
			},
		},
		enable_plugins = { lazydev = true },
	},
	web = {
		mason_null_ls = {
			"typescript-language-server",
			"html-lsp",
			"css-lsp",
			"json-lsp",
			"prettierd",
			"eslint_d",
		},
		mason_dap = {},
		treesitter = { "javascript", "typescript", "tsx", "html", "css", "json", "jsdoc" },
		formatting_servers = {
			"javascript",
			"javascriptreact",
			"typescript",
			"typescriptreact",
			"html",
			"css",
			"json",
		},
		lsp_configs = {},
		enable_plugins = {},
	},
	bash = {
		mason_null_ls = { "bash-language-server", "shfmt" },
		mason_dap = { "bash-debug-adapter" },
		treesitter = { "bash" },
		formatting_servers = { "sh", "bash", "zsh" },
		lsp_configs = {},
		enable_plugins = {},
	},
	toml = {
		mason_null_ls = { "taplo" },
		mason_dap = {},
		treesitter = { "toml" },
		formatting_servers = {},
		lsp_configs = {
			taplo = {
				cmd = { "taplo", "lsp", "stdio" },
				filetypes = { "toml" },
			},
		},
		enable_plugins = {},
	},
	yaml = {
		mason_null_ls = { "yaml-language-server" },
		mason_dap = {},
		treesitter = { "yaml" },
		formatting_servers = {},
		lsp_configs = {},
		enable_plugins = {},
	},
	ruby = {
		mason_null_ls = { "ruby-lsp", "solargraph" },
		mason_dap = {},
		treesitter = { "ruby" },
		formatting_servers = { "ruby" },
		lsp_configs = {
			ruby_lsp = {
				cmd = { "ruby-lsp" },
				filetypes = { "ruby", "eruby" },
				init_options = { "auto" },
			},
		},
		enable_plugins = {},
	},
	zig = {
		mason_null_ls = { "zls" },
		mason_dap = {},
		treesitter = { "zig" },
		formatting_servers = { "zig" },
		lsp_configs = {
			zls = {
				cmd = { "zls" },
				filetypes = { "zig" },
			},
		},
		enable_plugins = {},
	},
	docker = {
		mason_null_ls = { "dockerfile-language-server", "docker-compose-language-service" },
		mason_dap = {},
		treesitter = { "dockerfile" },
		formatting_servers = {},
		lsp_configs = {},
		enable_plugins = {},
	},
	perl = {
		mason_null_ls = { "perlnavigator" },
		mason_dap = {},
		treesitter = { "perl" },
		formatting_servers = {},
		lsp_configs = {
			perlnavigator = {
				cmd = { "perlnavigator" },
				filetypes = { "perl" },
			},
		},
		enable_plugins = {},
	},
	java = {
		mason_null_ls = { "jdtls", "google-java-format" },
		mason_dap = { "java-debug-adapter" },
		treesitter = { "java" },
		formatting_servers = { "java" },
		lsp_configs = {},
		enable_plugins = {},
	},
}

--- Expand a list of language names into config tables.
--- @param languages string[]
--- @return table with keys: mason_null_ls, mason_dap, treesitter, formatting_servers, lsp_configs, enable_plugins
M.expand = function(languages)
	local result = {
		mason_null_ls = {},
		mason_dap = {},
		treesitter = {},
		formatting_servers = {},
		lsp_configs = {},
		enable_plugins = {},
	}

	local seen_null_ls, seen_dap, seen_ts, seen_fmt = {}, {}, {}, {}

	for _, lang in ipairs(languages) do
		local bundle = M.bundles[lang]
		if not bundle then
			vim.notify("LushNvim: unknown language bundle '" .. lang .. "'", vim.log.levels.WARN)
			goto continue
		end

		for _, v in ipairs(bundle.mason_null_ls or {}) do
			if not seen_null_ls[v] then
				table.insert(result.mason_null_ls, v)
				seen_null_ls[v] = true
			end
		end
		for _, v in ipairs(bundle.mason_dap or {}) do
			if not seen_dap[v] then
				table.insert(result.mason_dap, v)
				seen_dap[v] = true
			end
		end
		for _, v in ipairs(bundle.treesitter or {}) do
			if not seen_ts[v] then
				table.insert(result.treesitter, v)
				seen_ts[v] = true
			end
		end
		for _, v in ipairs(bundle.formatting_servers or {}) do
			if not seen_fmt[v] then
				table.insert(result.formatting_servers, v)
				seen_fmt[v] = true
			end
		end
		for server, config in pairs(bundle.lsp_configs or {}) do
			if not result.lsp_configs[server] then
				result.lsp_configs[server] = config
			end
		end
		for key, val in pairs(bundle.enable_plugins or {}) do
			if result.enable_plugins[key] == nil then
				result.enable_plugins[key] = val
			end
		end

		::continue::
	end

	return result
end

--- Helper: append values from src list into dst list, skipping duplicates.
local function merge_list(dst, src)
	local seen = {}
	for _, v in ipairs(dst) do seen[v] = true end
	for _, v in ipairs(src) do
		if not seen[v] then
			table.insert(dst, v)
			seen[v] = true
		end
	end
end

--- Apply language bundle defaults to a user config table.
--- Manual entries in the config always win (append-if-missing / set-if-nil).
--- @param config table the user config module (M)
M.apply = function(config)
	if not config.languages or #config.languages == 0 then return end

	local expanded = M.expand(config.languages)

	config.mason_ensure_installed = config.mason_ensure_installed or {}
	config.mason_ensure_installed.null_ls = config.mason_ensure_installed.null_ls or {}
	merge_list(config.mason_ensure_installed.null_ls, expanded.mason_null_ls)

	config.mason_ensure_installed.dap = config.mason_ensure_installed.dap or {}
	merge_list(config.mason_ensure_installed.dap, expanded.mason_dap)

	config.treesitter_ensure_installed = config.treesitter_ensure_installed or {}
	merge_list(config.treesitter_ensure_installed, expanded.treesitter)

	config.formatting_servers = config.formatting_servers or {}
	config.formatting_servers["null_ls"] = config.formatting_servers["null_ls"] or {}
	merge_list(config.formatting_servers["null_ls"], expanded.formatting_servers)

	config.lsp_configs = config.lsp_configs or {}
	for server, conf in pairs(expanded.lsp_configs) do
		if not config.lsp_configs[server] then
			config.lsp_configs[server] = conf
		end
	end

	config.enable_plugins = config.enable_plugins or {}
	for key, val in pairs(expanded.enable_plugins) do
		if config.enable_plugins[key] == nil then
			config.enable_plugins[key] = val
		end
	end
end

return M
