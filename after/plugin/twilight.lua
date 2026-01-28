local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "twilight") then
  require("twilight").setup({
    dimming = {
      inactive = true,
    },
    context = 15,
  })
end
