local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "scope") then
  require("scope").setup({ restore_state = true })
end
