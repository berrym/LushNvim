-- Builder for snacks.nvim opts. Pulled out of lazy.lua so it can be re-called
-- at :LushReload time with fresh enable_plugins values. Toggling a snacks_X
-- flag in user/config.lua + :LushReload now actually takes effect, instead
-- of being baked into lazy's once-at-load opts snapshot.

local M = {}

function M.build()
  local utils = require("config.utils")
  local group = utils.get_plugin_group()
  local enabled = utils.enabled

  return {
    bigfile = { enabled = enabled(group, "snacks_bigfile") },
    quickfile = { enabled = enabled(group, "snacks_quickfile") },
    input = { enabled = enabled(group, "snacks_input") },
    words = { enabled = enabled(group, "snacks_words") },
    bufdelete = { enabled = enabled(group, "snacks_bufdelete") },
    dashboard = require("lush.dashboard").opts(enabled(group, "snacks_dashboard")),
    debug = { enabled = enabled(group, "snacks_debug") },
    git = { enabled = enabled(group, "snacks_git") },
    gitbrowse = { enabled = enabled(group, "snacks_gitbrowse") },
    indent = {
      enabled = enabled(group, "snacks_indent"),
      indent = {
        hl = {
          "RainbowRed",
          "RainbowGreen",
          "RainbowOrange",
          "RainbowBlue",
          "RainbowYellow",
          "RainbowViolet",
          "RainbowCyan",
        },
      },
      scope = { enabled = true },
    },
    rename = { enabled = enabled(group, "snacks_rename") },
    scroll = { enabled = enabled(group, "snacks_scroll") },
    toggle = { enabled = enabled(group, "snacks_toggle") },
    win = { enabled = enabled(group, "snacks_win") },
    zen = { enabled = enabled(group, "snacks_zen") },
    dim = { enabled = enabled(group, "snacks_zen") },
  }
end

return M
