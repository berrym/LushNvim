local create_user_command = vim.api.nvim_create_user_command
local colors = require("config.utils").colors

create_user_command("LushUpdate", function()
  require("config.utils").update_all()
end, { desc = "Updates plugins, mason packages, treesitter parsers" })

create_user_command("AstroTransparencyOn", function()
  require("astrotheme").setup({
    style = { transparent = true },
  })
  colors("astromars")
end, { desc = "Enable astrotheme transparency" })

create_user_command("AstroTransparencyOff", function()
  require("astrotheme").setup({
    style = { transparent = false },
  })
  colors("astromars")
end, { desc = "Disable astrotheme transparency" })

create_user_command("IblRainbowOn", function()
  require("ibl").setup({ indent = { highlight = _G.ibl_rainbow_highlight } })
end, { desc = "Enable colored indent markers" })

create_user_command("IblRainbowOff", function()
  require("ibl").setup()
end, { desc = "Disable colored indent markers" })
