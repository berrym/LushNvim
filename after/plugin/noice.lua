local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "noice") then
  -- Error sink: when autocommands.error_log is on, every error-level message
  -- is also appended to <state>/lush-errors.log via the "lushlog" backend
  -- (lua/noice/view/backend/lushlog.lua). stop = false lets the message carry
  -- on to its normal view, so nothing changes on screen. See :LushErrors.
  local auto = utils.get_user_config().autocommands or {}
  local error_log = auto.error_log ~= false
  local routes = {
    {
      filter = {
        event = "msg_show",
        kind = "search_count",
      },
      opts = { skip = true },
    },
  }
  if error_log then
    table.insert(routes, 1, {
      filter = { error = true },
      view = "lushlog",
      opts = { stop = false },
    })
  end

  require("noice").setup({
    presets = {
      bottom_search = true,
      command_palette = false,
      long_message_to_split = true,
      lsp_doc_border = true,
    },
    routes = routes,
    views = {
      lushlog = { backend = "lushlog" },
      cmdline_popup = {
        position = {
          row = "5",
          col = "50%",
        },
        size = {
          width = 60,
          height = "auto",
        },
      },
      popupmenu = {
        relative = "editor",
        position = {
          row = "8",
          col = "50%",
        },
        size = {
          width = 60,
          height = "auto",
        },
        border = {
          style = "rounded",
          padding = { 0, 1 },
        },
        win_options = {
          winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" },
        },
      },
    },
  })
end
