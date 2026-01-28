local utils = require("config.utils")
local group = utils.get_plugin_group()
local user_config = utils.get_user_config()
local sources = user_config.mason_ensure_installed and user_config.mason_ensure_installed.dap or {}

if utils.enabled(group, "lsp") then
  require("mason-nvim-dap").setup({
    ensure_installed = sources,
  })
end
