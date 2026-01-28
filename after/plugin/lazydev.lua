local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "lazydev") then
  require("lazydev").setup({})
end
