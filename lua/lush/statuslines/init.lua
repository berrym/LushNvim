-- Statusline style registry and dispatcher for LushNvim.
-- Each style lives in lua/lush/statuslines/<name>.lua and exports setup().
-- Selection is persisted through utils.statusline("name") in user/config.lua,
-- runtime picker at :LushStatusline / <leader>ul.

local M = {}

M.styles = {
	{ name = "lush",        label = "Lush",        blurb = "Signature LushNvim — language-aware components, the default" },
	{ name = "evil",        label = "Evil",        blurb = "Classic eviline" },
	{ name = "fox",         label = "Fox",         blurb = "Nightfox family (carbonfox, duskfox, …) with angled separators" },
	{ name = "tokyonight",  label = "Tokyonight",  blurb = "Powerline separators, tokyonight theme" },
	{ name = "catppuccin",  label = "Catppuccin",  blurb = "Rounded bubble sections, catppuccin theme" },
	{ name = "minimal",     label = "Minimal",     blurb = "Flat single-line, no chrome" },
	{ name = "auto",        label = "Auto",        blurb = "Adapts to whatever colorscheme is active" },
}

M.default = "lush"
M._current = nil

function M.list()
	return M.styles
end

function M.current()
	return M._current or M.default
end

function M.apply(name)
	name = name or M.default
	local ok_ll = pcall(require, "lualine")
	if not ok_ll then return false end
	local ok, style = pcall(require, "lush.statuslines." .. name)
	if not ok or type(style) ~= "table" or type(style.setup) ~= "function" then
		vim.notify("Unknown statusline style: " .. tostring(name) .. " — falling back to " .. M.default,
			vim.log.levels.WARN, { title = "LushStatusline" })
		name = M.default
		style = require("lush.statuslines." .. M.default)
	end
	style.setup()
	M._current = name
	return true
end

return M
