local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "claudecode") then
  require("claudecode").setup({
    -- Terminal configuration
    terminal_cmd = "claude",
    split_side = "right",
    split_width_percentage = 0.35,
    auto_close = true,

    -- Selection tracking
    track_selection = true,

    -- Server configuration
    auto_start = true,
    log_level = "warn",

    -- Diff integration
    diff_opts = {
      auto_close_on_accept = true,
      vertical_split = true,
    },
  })
end
