local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "copilot") then
	require("copilot").setup({
		-- Disable built-in suggestion/panel — blink-copilot handles display
		suggestion = { enabled = false },
		panel = { enabled = false },
		filetypes = {
			["*"] = true,
			help = false,
			gitcommit = false,
			gitrebase = false,
		},
	})
end
