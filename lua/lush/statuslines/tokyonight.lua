-- Tokyonight — powerline separators, tokyonight theme.
-- Angular, sharp, high contrast. Looks best on tokyonight-* but theme falls back to auto.

local M = {}

function M.setup()
  local utils = require("config.utils")
  local theme = "auto"
  if pcall(require, "lualine.themes.tokyonight") then
    theme = "tokyonight"
  end

  require("lualine").setup({
    options = {
      theme = theme,
      component_separators = { left = "", right = "" },
      section_separators = { left = "", right = "" },
      globalstatus = true,
      icons_enabled = true,
    },
    sections = {
      lualine_a = {
        { "mode", separator = { left = "" }, right_padding = 2 },
      },
      lualine_b = {
        { "branch", icon = "" },
        { "diff", symbols = { added = " ", modified = " ", removed = " " } },
      },
      lualine_c = {
        {
          "filename",
          path = 1,
          symbols = { modified = "  ", readonly = "  ", unnamed = "[No Name]" },
        },
        {
          "diagnostics",
          sources = { "nvim_diagnostic" },
          symbols = { error = " ", warn = " ", info = " ", hint = " " },
        },
      },
      lualine_x = {
        {
          function()
            return utils.get_attached_clients()
          end,
          icon = " ",
          cond = function()
            return vim.fn.winwidth(0) > 80
          end,
        },
        { "filetype", icon_only = false },
        "encoding",
        { "fileformat", icons_enabled = true },
      },
      lualine_y = { "progress" },
      lualine_z = {
        { "location", separator = { right = "" }, left_padding = 2 },
      },
    },
    inactive_sections = {
      lualine_a = { { "filename", path = 1 } },
      lualine_b = {},
      lualine_c = {},
      lualine_x = {},
      lualine_y = {},
      lualine_z = { "location" },
    },
    extensions = { "neo-tree", "lazy", "mason", "quickfix", "toggleterm", "trouble", "aerial" },
  })
end

return M
