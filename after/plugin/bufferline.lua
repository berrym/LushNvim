local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "bufferline") then
  local groups = require("bufferline.groups")
  require("bufferline").setup({
    options = {
      close_command = utils.safe_close_buffer,
      right_mouse_command = utils.safe_close_buffer,
      diagnostics = "nvim_lsp",
      -- Clean vertical bars between tabs, no slants; the active tab gets a
      -- left-edge accent bar as its indicator instead.
      separator_style = "thin",
      indicator = { style = "icon", icon = "▎" },
      diagnostics_indicator = function(count, level)
        local icon = level:match("error") and " " or " "
        return " " .. icon .. count
      end,
      -- Ordinal numbers enable <leader>1..9 jumping to tab position
      numbers = "ordinal",
      -- Hover shows full path; click X to close
      hover = { enabled = true, delay = 200, reveal = { "close" } },
      -- When neo-tree is open, shift the tab strip so it doesn't overlap
      offsets = {
        {
          filetype = "neo-tree",
          text = "File Explorer",
          text_align = "center",
          separator = true,
        },
      },
      -- Auto-grouping: pinned at front, tests grouped together,
      -- markdown/docs auto-collapse into a single tab
      groups = {
        options = { toggle_hidden_on_enter = true },
        items = {
          groups.builtin.pinned:with({ icon = "" }),
          {
            name = "Tests",
            icon = "",
            matcher = function(buf)
              return buf.name:match("_spec")
                or buf.name:match("_test")
                or buf.name:match("%.test%.")
                or buf.name:match("%.spec%.")
            end,
          },
          {
            name = "Docs",
            icon = "",
            matcher = function(buf)
              return buf.name:match("%.md$") or buf.name:match("%.txt$")
            end,
            auto_close = true,
          },
        },
      },
      show_buffer_close_icons = true,
      show_close_icon = false,
    },
  })
end
