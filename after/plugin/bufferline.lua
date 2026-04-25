local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "bufferline") then
  require("bufferline").setup({
    options = {
      close_command = utils.safe_close_buffer,
      right_mouse_command = utils.safe_close_buffer,
      diagnostics = "nvim_lsp",
      separator_style = "slant",
      diagnostics_indicator = function(count, level)
        local icon = level:match("error") and " " or " "
        return " " .. icon .. count
      end,
    },
  })
end
