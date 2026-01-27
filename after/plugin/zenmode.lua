local exist, user_config = pcall(require, "user.config")
local group = exist and type(user_config) == "table" and user_config.enable_plugins or {}
local enabled = require("config.utils").enabled

if enabled(group, "zen") then
  require("zen-mode").setup({
    plugins = {
      twilight = { enabled = true },
    },
  })
end
