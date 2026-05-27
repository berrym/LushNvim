local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "flash") then
  require("flash").setup({
    -- Defaults are sensible; tweak labels off in search to keep / behavior familiar.
    modes = {
      search = { enabled = false },
    },
  })
end
