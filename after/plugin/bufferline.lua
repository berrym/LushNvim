local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "bufferline") then
  require("bufferline").setup({
    options = {
      diagnostics = "nvim_lsp",
      separator_style = "slant",
      diagnostics_indicator = function(count, level)
        local icon = level:match("error") and " " or " "
        return " " .. icon .. count
      end,
    },
  })
end
