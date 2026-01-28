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
