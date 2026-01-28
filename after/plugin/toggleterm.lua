local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "toggleterm") then
  require("toggleterm").setup({
    open_mapping = [[<c-t>]],
    on_open = function(term)
      vim.cmd.startinsert()
      vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = term.bufnr, noremap = true, silent = true })
    end,
    size = 25,
    direction = "horizontal",
    float_opts = {
      border = "curved",
      winblend = 6,
    },
  })

  -- Create floating terminal toggles (accessible via require("config.terminal"))
  local Terminal = require("toggleterm.terminal").Terminal
  local terminal = {
    lazygit_toggle = utils.create_floating_terminal(Terminal, "lazygit"),
    gdu_toggle = utils.create_floating_terminal(Terminal, "gdu"),
    btop_toggle = utils.create_floating_terminal(Terminal, "btop"),
  }
  package.loaded["config.terminal"] = terminal
end
