local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "hop") then
  require("hop").setup({
    multi_windows = true,
  })
end
