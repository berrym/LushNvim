local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "notify") then
  local notify = require("notify")
  -- Suppresses the "no background highlight" warning when no terminal bg is set.
  notify.setup({ background_colour = "#000000" })
  vim.notify = notify
  _G.message = notify
end
