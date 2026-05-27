-- Minimal — flat, text-forward, no separators or icons.
-- Everything you need, nothing you don't. Good when you want the statusline to disappear.

local M = {}

function M.setup()
  require("lualine").setup({
    options = {
      theme = "auto",
      component_separators = " ",
      section_separators = "",
      globalstatus = true,
      icons_enabled = false,
    },
    sections = {
      lualine_a = { { "mode", fmt = string.lower } },
      lualine_b = { "branch" },
      lualine_c = {
        {
          "filename",
          path = 1,
          symbols = { modified = " *", readonly = " [RO]", unnamed = "[No Name]" },
        },
        { "diff" },
      },
      lualine_x = {
        { "diagnostics", sources = { "nvim_diagnostic" } },
        "filetype",
      },
      lualine_y = {},
      lualine_z = { "location" },
    },
    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = { { "filename", path = 1 } },
      lualine_x = { "location" },
      lualine_y = {},
      lualine_z = {},
    },
    extensions = { "neo-tree", "lazy", "mason", "quickfix", "trouble" },
  })
end

return M
