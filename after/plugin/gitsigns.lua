local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "gitsigns") then
  -- A review point set with <leader>am (lua/lush/review.lua) moves the diff
  -- base. Pass it back in here so :LushReload, which re-runs this setup, does
  -- not silently reset the gutter to the index while the mark is still set.
  local review_mark = vim.g.lush_review_mark
  require("gitsigns").setup({
    base = type(review_mark) == "table" and review_mark.sha or nil,
    on_attach = require("config.keybindings").gitsigns(),
  })
end
