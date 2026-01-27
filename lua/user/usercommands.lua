local create_user_command = vim.api.nvim_create_user_command
local colors = require("config.utils").colors

create_user_command("CatppuccinTransparencyOn", function()
  require("catppuccin").setup({
    transparent_background = true,
  })
  colors("catppuccin")
end, { desc = "Enable catppuccin transparency" })

create_user_command("CatppuccinTransparencyOff", function()
  require("catppuccin").setup({
    transparent_background = false,
  })
  colors("catppuccin")
end, { desc = "Disable catppuccin transparency" })

create_user_command("NightfoxTransparencyOn", function()
  require("nightfox").setup({
    options = { transparent = true },
  })
  colors("nightfox")
end, { desc = "Enable nightfox transparency" })

create_user_command("NightfoxTransparencyOff", function()
  require("nightfox").setup({
    options = { transparent = false },
  })
  colors("nightfox")
end, { desc = "Disable transparency" })

create_user_command("MonokaiProTransparencyOn", function()
  require("monokai-pro").setup({
    transparent_background = true,
  })
  colors("monokai-pro")
end, { desc = "Enable monokai-pro transparency" })

create_user_command("MonokaiProTransparencyOff", function()
  require("monokai-pro").setup({
    transparent_background = false,
  })
  colors("monokai-pro")
end, { desc = "Disable monokai-pro transparency" })

create_user_command("TokyonightTransparencyOn", function()
  require("tokyonight").setup({
    transparent = true,
  })
  colors("tokyonight")
end, { desc = "Enable tokyonight transparency" })

create_user_command("TokyonightTransparencyOff", function()
  require("tokyonight").setup({
    transparent = false,
  })
  colors("tokyonight")
end, { desc = "Disable tokyonight transparency" })
