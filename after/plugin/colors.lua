local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "astrotheme") then
  utils.colors("astromars")
end
