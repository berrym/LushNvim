local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "autopairs") then
  require("nvim-autopairs").setup({ map_c_w = true }) -- C-w will delete a pair
end
