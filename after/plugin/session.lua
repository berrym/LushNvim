local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "session_manager") then
  require("session_manager").setup({
    autosave_only_in_session = true,
    autoload_mode = require("session_manager.config").AutoloadMode.Disabled,
    autosave_ignore_dirs = {
      vim.fn.expand("~"), -- don't create a session for $HOME/
      "/tmp",
    },
    autosave_ignore_filetypes = {
      -- All buffers of these file types will be closed before the session is saved
      "ccc-ui",
      "gitcommit",
      "gitrebase",
      "qf",
    },
  })
end
