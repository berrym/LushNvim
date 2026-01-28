local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "zen") then
  require("zen-mode").setup({
    plugins = {
      twilight = { enabled = true },
    },
  })
end
