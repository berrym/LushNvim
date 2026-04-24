-- Lualine dispatcher — applies the style selected via utils.statusline() in user/config.lua.
-- Available styles live in lua/lush/statuslines/. Runtime switch: :LushStatusline / <leader>ul.

local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "lualine") then
	local styles = require("lush.statuslines")
	local choice = (type(utils.get_statusline) == "function" and utils.get_statusline()) or styles.default
	styles.apply(choice)
end
