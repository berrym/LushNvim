local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "project") then
  require("project_nvim").setup()
end
