-- Terminal wrappers built on snacks.terminal. Replaces toggleterm.nvim.
-- Exposes the same `config.terminal` API the rest of the codebase already
-- depends on (`gdu_toggle`, `btop_toggle`), plus binds the global <C-t>
-- toggle to a default shell terminal.

local utils = require("config.utils")
local group = utils.get_plugin_group()

if not utils.enabled(group, "snacks_terminal") then
  return
end

local ok, snacks = pcall(require, "snacks")
if not ok then
  return
end

-- Helper: open or toggle a named terminal in a floating window.
local function floating(cmd)
  return function()
    snacks.terminal.toggle(cmd, {
      win = {
        position = "float",
        border = "rounded",
        width = 0.85,
        height = 0.85,
      },
    })
  end
end

-- Default <C-t> shell terminal: horizontal split (matches old toggleterm behavior).
vim.keymap.set({ "n", "t" }, "<C-t>", function()
  snacks.terminal.toggle(nil, {
    win = { position = "bottom", height = 0.30 },
  })
end, { desc = "Toggle terminal" })
utils.track_keymap({ "n", "t" }, "<C-t>")

-- Named tool terminals — accessible via require("config.terminal").<name>_toggle().
package.loaded["config.terminal"] = {
  gdu_toggle = floating("gdu"),
  btop_toggle = floating("btop"),
}
