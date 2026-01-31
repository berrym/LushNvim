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

-- Hot-reload safe config components (options, keymaps, autocommands)
create_user_command("LushReload", function()
  local utils = require("config.utils")
  local reloaded = {}
  local failed = {}

  -- Modules that are safe to reload
  local safe_modules = {
    "config.options",
    "config.keybindings",
    "config.autocommands",
    "user.config",
  }

  for _, module in ipairs(safe_modules) do
    -- Clear from cache
    package.loaded[module] = nil
    -- Attempt to reload
    local ok, err = pcall(require, module)
    if ok then
      table.insert(reloaded, module)
    else
      table.insert(failed, module .. ": " .. tostring(err))
    end
  end

  -- Re-apply user options if user.config loaded
  local user_ok, user_config = pcall(require, "user.config")
  if user_ok and type(user_config) == "table" and user_config.options then
    utils.vim_opts(user_config.options)
  end

  -- Report results
  if #failed > 0 then
    utils.notify_error("Failed to reload:\n" .. table.concat(failed, "\n"), "LushReload")
  end
  if #reloaded > 0 then
    utils.notify_info("Reloaded: " .. table.concat(reloaded, ", "), "LushReload")
  end
end, { desc = "Hot-reload safe config components (options, keymaps, autocommands)" })
