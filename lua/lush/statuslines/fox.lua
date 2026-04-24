-- Fox — nightfox family (carbonfox, nightfox, duskfox, dayfox, dawnfox,
-- nordfox, terafox). Pulls palette-aware theme from nightfox's own lualine
-- generator so the statusline colors track the active fox variant. Falls
-- back to carbonfox when a non-fox colorscheme is active.

local M = {}

local fox_variants = {
	nightfox  = true,
	dayfox    = true,
	dawnfox   = true,
	duskfox   = true,
	nordfox   = true,
	terafox   = true,
	carbonfox = true,
}

local function active_fox_style()
	local scheme = vim.g.colors_name
	if scheme and fox_variants[scheme] then return scheme end
	return "carbonfox"
end

function M.setup()
	local utils = require("config.utils")

	-- Nightfox's generator returns a full lualine theme table with mode-specific
	-- a/b/c sections and faded b backgrounds. If nightfox isn't installed yet,
	-- fall back to "auto" so the style still loads.
	local theme = "auto"
	local ok, gen = pcall(require, "nightfox.util.lualine")
	if ok then
		local ok2, built = pcall(gen, active_fox_style())
		if ok2 then theme = built end
	end

	require("lualine").setup({
		options = {
			theme = theme,
			-- Thin angled separators — distinct from tokyonight's solid powerline
			-- and catppuccin's rounded bubbles. Pairs well with the fox palette.
			component_separators = { left = "", right = "" },
			section_separators   = { left = "", right = "" },
			globalstatus = true,
			icons_enabled = true,
		},
		sections = {
			lualine_a = { { "mode" } },
			lualine_b = {
				{ "branch", icon = "" },
				{ "diff", symbols = { added = " ", modified = " ", removed = " " } },
			},
			lualine_c = {
				{
					"filename",
					path = 1,
					symbols = { modified = "  ", readonly = "  ", unnamed = "[No Name]" },
				},
				{
					"diagnostics",
					sources = { "nvim_diagnostic" },
					symbols = { error = " ", warn = " ", info = " ", hint = " " },
				},
			},
			lualine_x = {
				{
					function() return utils.get_attached_clients() end,
					icon = " ",
					cond = function() return vim.fn.winwidth(0) > 80 end,
				},
				{ "filetype", icon_only = true, padding = { left = 1, right = 0 } },
				{ "encoding", fmt = string.upper, cond = function() return vim.fn.winwidth(0) > 90 end },
				{ "fileformat" },
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
end

return M
