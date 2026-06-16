-- Builder for snacks.nvim opts, kept as the single source of truth so the
-- opts table isn't inlined into lazy.lua. lazy.nvim calls this once at startup
-- via the plugin `opts` function. snacks.setup is one-shot (no re-config API),
-- so toggling a snacks_X flag in user/config.lua requires a full restart --
-- :LushReload cannot live-flip snacks modules.

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
    lazygit = { enabled = enabled(group, "snacks_lazygit") },
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
    terminal = { enabled = enabled(group, "snacks_terminal") },
    toggle = { enabled = enabled(group, "snacks_toggle") },
    win = { enabled = enabled(group, "snacks_win") },
    zen = { enabled = enabled(group, "snacks_zen") },
    dim = { enabled = enabled(group, "snacks_zen") },
  }
end

return M
