local exist, user_config = pcall(require, "user.config")
local group = exist and type(user_config) == "table" and user_config.enable_plugins or {}
local enabled = require("config.utils").enabled

if enabled(group, "aerial") then
  require("aerial").setup({
    highlight_on_hover = true,
    autojump = true,
    highlight_on_jump = false,
    manage_folds = true,
    show_guides = true,
  })
end
