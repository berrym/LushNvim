local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "telescope") then
  local telescope = require("telescope")
  telescope.setup({
    defaults = {
      file_ignore_patterns = { "node_modules", ".git/" },
    },
    pickers = {
      find_files = {
        hidden = true,
      },
      git_files = {
        show_untracked = true,
      },
    },
  })
  if utils.enabled(group, "scope") then
    telescope.load_extension("scope")
  end
  if utils.enabled(group, "aerial") then
    telescope.load_extension("aerial")
  end
  if utils.enabled(group, "notify") then
    telescope.load_extension("notify")
  end
  if utils.enabled(group, "noice") then
    telescope.load_extension("noice")
  end
  if utils.enabled(group, "projects") then
    telescope.load_extension("projects")
  end
end
