-- Set leader keys early, before lazy.nvim loads plugins
-- This ensures <leader> mappings in after/plugin files use the correct key
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Compatibility shim for plugins using deprecated vim.lsp.buf_get_clients()
-- This silently redirects to the modern API, fixing warnings from plugins like project.nvim
vim.lsp.buf_get_clients = function(bufnr)
  return vim.lsp.get_clients({ buffer = bufnr or 0 })
end

require("config.lazy")

for _, source in ipairs({
  "config.options",
  "config.keybindings",
  "config.utils",
  "config.autocommands",
  "config.lsp",
  "config.usercommands",
}) do
  local status_ok, fault = pcall(require, source)
  if not status_ok then
    vim.api.nvim_err_writeln("Failed to load " .. source .. "\n\n" .. fault)
  end
end

local exist, user_config = pcall(require, "user.config")
if exist and type(user_config) == "table" and user_config.custom_conf then
  user_config.custom_conf()
else
  -- First-run detection: no user config found
  local config_dir = vim.fn.stdpath("config")
  local user_config_path = config_dir .. "/lua/user/config.lua"
  if vim.fn.filereadable(user_config_path) == 0 then
    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      callback = function()
        local example = config_dir .. "/lua/example_user_config.lua"
        local user_dir = config_dir .. "/lua/user"
        vim.notify(
          "Welcome to LushNvim!\n\n"
            .. "No user config found. To get started:\n\n"
            .. "  cp lua/example_user_config.lua lua/user/config.lua\n\n"
            .. "Or run :LushInit to set it up automatically.\n"
            .. "Then edit lua/user/config.lua to customize.\n"
            .. "Run :checkhealth lush to verify your setup.",
          vim.log.levels.INFO,
          { title = "LushNvim" }
        )
        -- Provide :LushInit command for automatic setup
        vim.api.nvim_create_user_command("LushInit", function()
          vim.fn.mkdir(user_dir, "p")
          if vim.fn.filereadable(example) == 1 then
            vim.fn.system({ "cp", example, user_config_path })
            vim.notify(
              "User config created at lua/user/config.lua\n"
                .. "Restart nvim to apply. Edit the file to customize.",
              vim.log.levels.INFO,
              { title = "LushNvim" }
            )
          else
            vim.notify("Example config not found at " .. example, vim.log.levels.ERROR, { title = "LushNvim" })
          end
        end, { desc = "Create user config from example template" })
      end,
    })
  end
end
