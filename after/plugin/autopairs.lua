local exist, user_config = pcall(require, "user.config")
local group = exist and type(user_config) == "table" and user_config.enable_plugins or {}
local enabled = require("config.utils").enabled

if enabled(group, "autopairs") then
  require("nvim-autopairs").setup({ map_c_w = true }) -- C-w will delete a pair
end
