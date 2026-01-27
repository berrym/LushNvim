local exist, user_config = pcall(require, "user.config")
local group = exist and type(user_config) == "table" and user_config.enable_plugins or {}
local enabled = require("config.utils").enabled

if enabled(group, "toggleterm") then
  local opts = {
    open_mapping = [[<c-t>]],
    on_open = function(term)
      vim.cmd("startinsert!")
      vim.api.nvim_buf_set_keymap(
        term.bufnr,
        "n",
        "q",
        "<cmd>close<CR>",
        { noremap = true, silent = true }
      )
    end,
    on_close = function(_)
      vim.cmd("startinsert!")
    end,
    size = 25,
    direction = "horizontal",
    float_opts = {
      border = "curved",
      winblend = 6,
    },
  }
  require("toggleterm").setup(opts)

  local create_floating_terminal = require("config.utils").create_floating_terminal
  local terminal = require("toggleterm.terminal").Terminal

  local M = {}
  M.lazygit_toggle = create_floating_terminal(terminal, "lazygit")
  M.gdu_toggle = create_floating_terminal(terminal, "gdu")
  M.btop_toggle = create_floating_terminal(terminal, "btop")
  _G.terminal = M
end
