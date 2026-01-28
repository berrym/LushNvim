local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "neotree") then
  require("neo-tree").setup({
    close_if_last_window = true,
    popup_border_style = "rounded",
    enable_git_status = true,
    enable_diagnostics = true,
    open_files_do_not_replace_types = {
      "terminal",
      "toggleterm",
      "trouble",
      "qf",
      "gitcommit",
      "gitrebase",
    },
    sort_case_insensitive = false,
    filesystem = {
      filtered_items = { visible = true },
      follow_current_file = {
        enabled = true,
        leave_dirs_open = false,
      },
      hijack_netrw_behavior = "open_current",
    },
    buffers = {
      follow_current_file = {
        enabled = true,          -- This will find and focus the file in the active buffer every time
        --                       -- the current file is changed while the tree is open.
        leave_dirs_open = false, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
      },
    },
  })
end
