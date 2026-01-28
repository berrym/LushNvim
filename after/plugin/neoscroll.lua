local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "neoscroll") then
  require("neoscroll").setup({
    respect_scrolloff = true,
  })
end
