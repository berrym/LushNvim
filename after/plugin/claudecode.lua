local exist, custom_config = pcall(require, "custom.custom_config")
local group = exist and type(custom_config) == "table" and custom_config.enable_plugins or {}
local enabled = require("config.utils").enabled

if enabled(group, "claudecode") then
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
