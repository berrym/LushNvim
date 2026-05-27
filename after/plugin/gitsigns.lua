local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "gitsigns") then
  require("gitsigns").setup({
    on_attach = require("config.keybindings").gitsigns(),
  })
end
