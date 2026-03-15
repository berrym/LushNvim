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
    event_handlers = {
      {
        event = "neo_tree_window_after_open",
        handler = function()
          -- Move bottom-positioned windows (terminals, Claude) below neo-tree
          -- so neo-tree only spans the top row, not full editor height
          vim.schedule(function()
            local prev_win = vim.api.nvim_get_current_win()
            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
              if vim.api.nvim_win_is_valid(win) then
                local buf = vim.api.nvim_win_get_buf(win)
                local bt = vim.bo[buf].buftype
                local ft = vim.bo[buf].filetype
                local cfg = vim.api.nvim_win_get_config(win)
                -- Skip floating windows
                if not cfg.relative or cfg.relative == "" then
                  -- Detect terminal/toggleterm/claude windows
                  local is_bottom = bt == "terminal"
                      or ft == "toggleterm"
                      or (bt == "terminal" and vim.api.nvim_buf_get_name(buf):match("claude"))
                  if is_bottom then
                    local height = vim.api.nvim_win_get_height(win)
                    vim.api.nvim_set_current_win(win)
                    vim.cmd("wincmd J")
                    -- Restore height after moving to full-width bottom
                    pcall(vim.api.nvim_win_set_height, win, height)
                  end
                end
              end
            end
            if vim.api.nvim_win_is_valid(prev_win) then
              vim.api.nvim_set_current_win(prev_win)
            end
          end)
        end,
      },
    },
    filesystem = {
      filtered_items = { visible = true },
      follow_current_file = {
        enabled = true,
        leave_dirs_open = false,
      },
      use_libuv_file_watcher = true,
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
