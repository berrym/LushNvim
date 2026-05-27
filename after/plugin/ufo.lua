local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "ufo") then
  require("ufo").setup()
end
