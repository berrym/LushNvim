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
end
