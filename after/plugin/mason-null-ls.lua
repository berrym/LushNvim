local utils = require("config.utils")
local group = utils.get_plugin_group()
local user_config = utils.get_user_config()
local sources = user_config.mason_ensure_installed and user_config.mason_ensure_installed.null_ls or {}

if utils.enabled(group, "lsp") then
  require("mason-null-ls").setup({
    automatic_installation = true,
    ensure_installed = sources,
  })
end
