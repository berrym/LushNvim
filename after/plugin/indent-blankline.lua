local exist, user_config = pcall(require, "user.config")
local group = exist and type(user_config) == "table" and user_config.enable_plugins or {}
local enabled = require("config.utils").enabled

if enabled(group, "indent_blankline") then
  if enabled(group, "indent_blankline_rainbow") then
    -- configure multiple indent colors for indent-blankline
    _G.ibl_rainbow_highlight = {
      "RainbowRed",
      "RainbowGreen",
      "RainbowOrange",
      "RainbowBlue",
      "RainbowYellow",
      "RainbowViolet",
      "RainbowCyan",
    }
    _G.ibl_hooks = require("ibl.hooks")
    -- create the highlight groups in the highlight setup hook, so they are reset
    -- every time the colorscheme changes
    _G.ibl_hooks.register(_G.ibl_hooks.type.HIGHLIGHT_SETUP, function()
      vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
      vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
      vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
      vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
      vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
      vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
      vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
    end)
    -- end configuring multiple indent colors
    require("ibl").setup({ indent = { highlight = _G.ibl_rainbow_highlight } })
  else
    require("ibl").setup()
  end
end
