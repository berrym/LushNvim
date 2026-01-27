local exist, user_config = pcall(require, "user.config")
local group = exist and type(user_config) == "table" and user_config.enable_plugins or {}
local sources = exist
    and type(user_config) == "table"
    and user_config.mason_ensure_installed
    and user_config.mason_ensure_installed.null_ls
    or {}
local enabled = require("config.utils").enabled

if enabled(group, "lsp") then
  require("mason-null-ls").setup({
    automatic_installation = true,
    ensure_installed = sources,
  })
end
