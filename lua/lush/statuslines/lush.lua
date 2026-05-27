-- Lush — the signature LushNvim statusline.
-- Fox-restrained shape with bubble-cap section separators for visual
-- signature, plus a single project-identifying component (Python venv,
-- Rust crate, Go module, JS/TS package, C/C++ build system) that only
-- shows on wide windows so it's contextual rather than constant.

local M = {}

-- ──────────────────────────────────────────────────────────────────────────────
-- Language detection helpers. All results cached per-buffer (`b:lush_*`).
-- ──────────────────────────────────────────────────────────────────────────────

-- Read first regex hit from a file without slurping the whole thing.
local function scan_first(path, pattern, max_lines)
	local fd = io.open(path, "r")
	if not fd then return nil end
	local n = 0
	for line in fd:lines() do
		n = n + 1
		local m = line:match(pattern)
		if m then fd:close() return m end
		if max_lines and n >= max_lines then break end
	end
	fd:close()
	return nil
end

local function find_root(markers)
	local start = vim.fn.expand("%:p:h")
	if start == "" then start = vim.fn.getcwd() end
	local found = vim.fs.find(markers, { upward = true, path = start, type = "file" })[1]
	return found and vim.fs.dirname(found) or nil, found
end

-- Python: show $VIRTUAL_ENV or $CONDA_DEFAULT_ENV basename.
local function python_venv()
	if vim.bo.filetype ~= "python" then return "" end
	local venv = os.getenv("VIRTUAL_ENV") or os.getenv("CONDA_DEFAULT_ENV")
	if not venv or venv == "" then return "" end
	return "󰌠 " .. vim.fn.fnamemodify(venv, ":t")
end

-- Rust: crate name from Cargo.toml.
local function rust_crate()
	if vim.bo.filetype ~= "rust" then return "" end
	if vim.b.lush_rust ~= nil then return vim.b.lush_rust end
	local _, cargo = find_root({ "Cargo.toml" })
	local name = cargo and scan_first(cargo, '^%s*name%s*=%s*"([^"]+)"', 40) or ""
	vim.b.lush_rust = name ~= "" and (" " .. name) or ""
	return vim.b.lush_rust
end

-- Go: module name from go.mod.
local function go_module()
	if vim.bo.filetype ~= "go" and vim.bo.filetype ~= "gomod" then return "" end
	if vim.b.lush_go ~= nil then return vim.b.lush_go end
	local _, gomod = find_root({ "go.mod" })
	local name = gomod and scan_first(gomod, "^module%s+(%S+)", 10) or ""
	if name ~= "" then name = vim.fn.fnamemodify(name, ":t") end
	vim.b.lush_go = name ~= "" and (" " .. name) or ""
	return vim.b.lush_go
end

-- JS/TS: package name from nearest package.json (shallow parse — just the "name" field).
local function node_package()
	local ft = vim.bo.filetype
	if ft ~= "javascript" and ft ~= "typescript" and ft ~= "javascriptreact"
		and ft ~= "typescriptreact" and ft ~= "vue" and ft ~= "svelte" and ft ~= "json" then
		return ""
	end
	if vim.b.lush_node ~= nil then return vim.b.lush_node end
	local _, pkg = find_root({ "package.json" })
	local name = pkg and scan_first(pkg, '"name"%s*:%s*"([^"]+)"', 30) or ""
	vim.b.lush_node = name ~= "" and (" " .. name) or ""
	return vim.b.lush_node
end

-- C/C++: detected build system.
local function c_build_system()
	local ft = vim.bo.filetype
	if ft ~= "c" and ft ~= "cpp" and ft ~= "h" and ft ~= "hpp" and ft ~= "objc" and ft ~= "objcpp" then
		return ""
	end
	if vim.b.lush_cbuild ~= nil then return vim.b.lush_cbuild end
	local root = find_root({ "meson.build", "CMakeLists.txt", "Makefile", "configure.ac", "configure.in" })
	if not root then vim.b.lush_cbuild = "" return "" end
	local tag =
		(vim.fn.filereadable(root .. "/meson.build") == 1 and "󰫴 meson")
		or (vim.fn.filereadable(root .. "/CMakeLists.txt") == 1 and "󱁤 cmake")
		or (vim.fn.filereadable(root .. "/configure.ac") == 1 and "󱌢 autoconf")
		or (vim.fn.filereadable(root .. "/configure.in") == 1 and "󱌢 autoconf")
		or (vim.fn.filereadable(root .. "/Makefile") == 1 and " make")
		or ""
	vim.b.lush_cbuild = tag
	return tag
end

local function language_component()
	local out = python_venv()
	if out ~= "" then return out end
	out = rust_crate()
	if out ~= "" then return out end
	out = go_module()
	if out ~= "" then return out end
	out = node_package()
	if out ~= "" then return out end
	return c_build_system()
end

-- Clear per-buffer caches when the file changes on disk.
vim.api.nvim_create_autocmd({ "BufWritePost", "DirChanged" }, {
	group = vim.api.nvim_create_augroup("LushStatuslineCache", { clear = true }),
	callback = function(args)
		pcall(vim.api.nvim_buf_set_var, args.buf, "lush_rust", nil)
		pcall(vim.api.nvim_buf_set_var, args.buf, "lush_go", nil)
		pcall(vim.api.nvim_buf_set_var, args.buf, "lush_node", nil)
		pcall(vim.api.nvim_buf_set_var, args.buf, "lush_cbuild", nil)
	end,
})

-- ──────────────────────────────────────────────────────────────────────────────
-- Theme resolution — follows the active colorscheme so caps pop on every
-- palette LushNvim ships with. Falls back to "auto" for unknown themes.
-- ──────────────────────────────────────────────────────────────────────────────

local fox_variants = {
	nightfox = true, dayfox = true, dawnfox = true,
	duskfox = true, nordfox = true, terafox = true, carbonfox = true,
}

local function pick_theme()
	local scheme = vim.g.colors_name or ""

	-- nightfox family has its own generator that builds a full lualine theme
	-- tracking the active fox variant's palette.
	if fox_variants[scheme] then
		local ok, gen = pcall(require, "nightfox.util.lualine")
		if ok then
			local ok2, built = pcall(gen, scheme)
			if ok2 then return built end
		end
	end

	-- Named lualine themes that ship distinct a/b/c bgs (caps render cleanly).
	if scheme:match("^tokyonight") then
		if pcall(require, "lualine.themes.tokyonight") then return "tokyonight" end
	end
	if scheme:match("^catppuccin") then
		if pcall(require, "lualine.themes.catppuccin") then return "catppuccin" end
	end

	return "auto"
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Setup.
-- ──────────────────────────────────────────────────────────────────────────────

function M.setup()
	local utils = require("config.utils")

	require("lualine").setup({
		options = {
			theme = pick_theme(),
			component_separators = { left = "│", right = "│" },
			section_separators = { left = "", right = "" },
			globalstatus = true,
			icons_enabled = true,
		},
		sections = {
			lualine_a = { { "mode", fmt = function(s) return " " .. s end } },
			lualine_b = {
				{ "branch", icon = "" },
				{ "diff", symbols = { added = " ", modified = " ", removed = " " } },
			},
			lualine_c = {
				{
					"filename",
					path = 1,
					symbols = { modified = " ●", readonly = " ", unnamed = "[No Name]" },
				},
				{
					"diagnostics",
					sources = { "nvim_diagnostic" },
					symbols = { error = " ", warn = " ", info = " ", hint = " " },
				},
			},
			lualine_x = {
				{
					language_component,
					cond = function() return vim.fn.winwidth(0) > 100 end,
				},
				{
					function() return utils.get_attached_clients() end,
					icon = "",
					cond = function() return vim.fn.winwidth(0) > 80 end,
				},
				{ "filetype", icon_only = true, padding = { left = 1, right = 0 } },
				{ "encoding", fmt = string.upper, cond = function() return vim.fn.winwidth(0) > 90 end },
			},
			lualine_y = { "progress" },
			lualine_z = { "location" },
		},
		inactive_sections = {
			lualine_a = { { "filename", path = 1 } },
			lualine_b = {},
			lualine_c = {},
			lualine_x = {},
			lualine_y = {},
			lualine_z = { "location" },
		},
		extensions = { "neo-tree", "lazy", "mason", "quickfix", "toggleterm", "trouble", "aerial", "nvim-dap-ui" },
	})

	-- Re-resolve lualine theme whenever the colorscheme changes so the
	-- statusline tracks :LushColors / :colorscheme switches automatically.
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("LushStatuslineTheme", { clear = true }),
		callback = function()
			local ok, lualine = pcall(require, "lualine")
			if not ok then return end
			local cfg = lualine.get_config()
			cfg.options.theme = pick_theme()
			lualine.setup(cfg)
		end,
	})
end

return M
