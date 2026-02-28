-- LushNvim health check (:checkhealth lush)

local M = {}

M.check = function()
	local h = vim.health

	-- Neovim version
	h.start("Neovim Version")
	local v = vim.version()
	local version_str = string.format("%d.%d.%d", v.major, v.minor, v.patch)
	if v.minor >= 10 then
		h.ok("Neovim " .. version_str)
	else
		h.error("Neovim 0.10+ required, found " .. version_str)
	end

	-- External tools
	h.start("External Tools")
	local tools = { "git", "node", "python3", "go", "cargo", "rg", "fd", "lazygit" }
	for _, tool in ipairs(tools) do
		if vim.fn.executable(tool) == 1 then
			h.ok(tool .. " found")
		else
			h.warn(tool .. " not found")
		end
	end

	-- User config
	local ok_uc, uc = pcall(require, "user.config")
	if not ok_uc or type(uc) ~= "table" then
		h.start("User Config")
		h.error("Failed to load user.config")
		return
	end

	-- Mason packages
	h.start("Mason Packages (LSP/Formatters/Linters)")
	local ok_reg, registry = pcall(require, "mason-registry")
	if ok_reg then
		local null_ls_tools = uc.mason_ensure_installed and uc.mason_ensure_installed.null_ls or {}
		for _, tool in ipairs(null_ls_tools) do
			if registry.is_installed(tool) then
				h.ok(tool)
			else
				h.warn(tool .. " not installed  :MasonInstall " .. tool)
			end
		end
	else
		h.warn("Mason registry not available")
	end

	h.start("Mason Packages (DAP Adapters)")
	if ok_reg then
		-- mason-nvim-dap uses adapter names that differ from mason-registry package names
		local dap_name_map = {}
		local ok_dap_src, dap_src = pcall(require, "mason-nvim-dap.mappings.source")
		if ok_dap_src then
			dap_name_map = dap_src.nvim_dap_to_package or {}
		end
		local dap_tools = uc.mason_ensure_installed and uc.mason_ensure_installed.dap or {}
		for _, tool in ipairs(dap_tools) do
			local pkg_name = dap_name_map[tool] or tool
			if registry.is_installed(pkg_name) then
				h.ok(tool .. (pkg_name ~= tool and " (" .. pkg_name .. ")" or ""))
			else
				h.warn(tool .. " not installed  :MasonInstall " .. pkg_name)
			end
		end
	else
		h.warn("Mason registry not available")
	end

	-- LSP servers
	h.start("LSP Servers")
	if uc.lsp_configs then
		for server_name, config in pairs(uc.lsp_configs) do
			local cmd = config.cmd
			if cmd and cmd[1] then
				if vim.fn.executable(cmd[1]) == 1 then
					h.ok(server_name .. " (" .. cmd[1] .. ")")
				else
					h.warn(server_name .. ": " .. cmd[1] .. " not found on PATH")
				end
			else
				h.info(server_name .. " (Mason-managed)")
			end
		end
	end

	-- Treesitter parsers
	h.start("Treesitter Parsers")
	if uc.treesitter_ensure_installed then
		local installed_count = 0
		local missing = {}
		for _, parser in ipairs(uc.treesitter_ensure_installed) do
			if pcall(vim.treesitter.language.inspect, parser) then
				installed_count = installed_count + 1
			else
				table.insert(missing, parser)
			end
		end
		local total = #uc.treesitter_ensure_installed
		h.ok(installed_count .. "/" .. total .. " parsers installed")
		if #missing > 0 then
			h.warn("Missing: " .. table.concat(missing, ", "))
		end
	end

	-- Language bundles
	if uc.languages and #uc.languages > 0 then
		h.start("Language Bundles")
		h.info("Active: " .. table.concat(uc.languages, ", "))
		local ok_lang, lang_mod = pcall(require, "config.languages")
		if ok_lang then
			for _, lang in ipairs(uc.languages) do
				if lang_mod.bundles[lang] then
					h.ok(lang)
				else
					h.error("Unknown bundle: " .. lang)
				end
			end
			h.info("Available: " .. table.concat(vim.tbl_keys(lang_mod.bundles), ", "))
		end
	end
end

return M
