-- Lush — the signature LushNvim statusline.
-- Language-aware components for Python (venv), Rust (crate), Go (module),
-- JS/TS (package), C/C++ (build system). Colors inherit from the active
-- colorscheme via theme = "auto", with a few accents overlaid.

local M = {}

-- ──────────────────────────────────────────────────────────────────────────────
-- Mode palette — auto-derives from colorscheme so it reads well on any theme.
-- ──────────────────────────────────────────────────────────────────────────────
local function hl(name, fallback)
	local ok, h = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
	if not ok or not h or (not h.fg and not h.bg) then return fallback end
	local fg = h.fg and string.format("#%06x", h.fg) or fallback
	return fg
end

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
	-- dispatch by filetype; cheapest check first
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

-- ──────────────────────────────────────────────────────────────────────────────
-- Misc components.
-- ──────────────────────────────────────────────────────────────────────────────

local function macro_recording()
	local reg = vim.fn.reg_recording()
	if reg == "" then return "" end
	return " recording @" .. reg
end

-- Warn when a buffer mixes tabs and spaces in leading indentation.
local function mixed_indent()
	if vim.b.lush_mixed ~= nil then return vim.b.lush_mixed end
	local space_pat = vim.fn.search([[\v^ +]], "nw")
	local tab_pat = vim.fn.search([[\v^\t+]], "nw")
	local mixed = (space_pat > 0 and tab_pat > 0)
	vim.b.lush_mixed = mixed and " mixed-indent" or ""
	return vim.b.lush_mixed
end

-- LSP progress spinner — animates while any server is doing work.
local spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local function lsp_spinner()
	local progress = vim.lsp.status()
	if progress == "" or progress == nil then return "" end
	local frame = spinner_frames[(math.floor(vim.uv.now() / 80) % #spinner_frames) + 1]
	return frame .. " " .. progress:gsub("%s+", " "):sub(1, 40)
end

-- Scroll-position bar: 8 block glyphs mapped to percent-through-file.
local scroll_glyphs = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }
local function scroll_bar()
	local cur = vim.api.nvim_win_get_cursor(0)[1]
	local total = vim.api.nvim_buf_line_count(0)
	if total == 0 then return scroll_glyphs[1] end
	local idx = math.floor((cur - 1) / math.max(total - 1, 1) * (#scroll_glyphs - 1)) + 1
	return scroll_glyphs[math.min(idx, #scroll_glyphs)]
end

-- Clear per-buffer caches when the file changes on disk or buffer is re-entered.
vim.api.nvim_create_autocmd({ "BufWritePost", "DirChanged" }, {
	group = vim.api.nvim_create_augroup("LushStatuslineCache", { clear = true }),
	callback = function(args)
		pcall(vim.api.nvim_buf_set_var, args.buf, "lush_rust", nil)
		pcall(vim.api.nvim_buf_set_var, args.buf, "lush_go", nil)
		pcall(vim.api.nvim_buf_set_var, args.buf, "lush_node", nil)
		pcall(vim.api.nvim_buf_set_var, args.buf, "lush_cbuild", nil)
		pcall(vim.api.nvim_buf_set_var, args.buf, "lush_mixed", nil)
	end,
})

-- ──────────────────────────────────────────────────────────────────────────────
-- Setup.
-- ──────────────────────────────────────────────────────────────────────────────

function M.setup()
	local utils = require("config.utils")
	local group = utils.get_plugin_group()

	local accent = {
		branch    = hl("Keyword",  "#a9a1e1"),
		lang      = hl("Function", "#51afef"),
		lsp       = hl("String",   "#98be65"),
		macro     = hl("Error",    "#ec5f67"),
		mixed     = hl("WarningMsg", "#ff8800"),
		session   = hl("Special",  "#eCBe7B"),
		bar       = hl("Statement", "#51afef"),
	}

	local dap_component = nil
	if utils.enabled(group, "dap") then
		dap_component = {
			function()
				local ok, dap = pcall(require, "dap")
				if not ok then return "" end
				return " " .. (dap.status() ~= "" and dap.status() or "active")
			end,
			cond = function()
				local ok, dap = pcall(require, "dap")
				return ok and dap.session() ~= nil
			end,
			color = { fg = "#ff8800", gui = "bold" },
		}
	end

	local session_component = {
		function()
			if vim.g.persisting then return " session" end
			if vim.g.persisting == false then return " no session" end
			return ""
		end,
		cond = function() return vim.g.persisting ~= nil end,
		color = function()
			if vim.g.persisting then return { fg = accent.lsp } end
			return { fg = accent.session }
		end,
	}

	local lualine_c = {
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
		{ macro_recording, color = { fg = accent.macro, gui = "bold" } },
	}
	if dap_component then table.insert(lualine_c, dap_component) end

	require("lualine").setup({
		options = {
			theme = "auto",
			component_separators = { left = "│", right = "│" },
			section_separators = { left = "", right = "" },
			globalstatus = true,
			icons_enabled = true,
			refresh = { statusline = 200 },
		},
		sections = {
			lualine_a = { { "mode", fmt = function(s) return " " .. s end } },
			lualine_b = {
				{ "branch", icon = "", color = { fg = accent.branch, gui = "bold" } },
				{ "diff", symbols = { added = " ", modified = " ", removed = " " } },
			},
			lualine_c = lualine_c,
			lualine_x = {
				{ language_component, color = { fg = accent.lang, gui = "bold" } },
				{ mixed_indent, color = { fg = accent.mixed, gui = "bold" } },
				session_component,
				{ lsp_spinner, color = { fg = accent.lsp } },
				{
					function() return utils.get_attached_clients() end,
					icon = "",
					color = { fg = accent.lsp, gui = "bold" },
					cond = function() return vim.fn.winwidth(0) > 100 end,
				},
				{ "filetype", icon_only = true, padding = { left = 1, right = 0 } },
				{ "encoding", fmt = string.upper, cond = function() return vim.fn.winwidth(0) > 90 end },
			},
			lualine_y = { "progress" },
			lualine_z = {
				"location",
				{ scroll_bar, color = { fg = accent.bar, gui = "bold" }, padding = { left = 0, right = 1 } },
			},
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
end

return M
