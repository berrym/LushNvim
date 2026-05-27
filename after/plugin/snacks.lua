local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "snacks") then
  local ok, snacks = pcall(require, "snacks")
  if ok then
    -- Toggle mappings using snacks.toggle
    snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
    snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
    snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
    snacks.toggle.diagnostics():map("<leader>ud")
    snacks.toggle.line_number():map("<leader>ul")
    snacks.toggle
      .option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
      :map("<leader>uc")
    snacks.toggle.treesitter():map("<leader>uT")
    snacks.toggle.inlay_hints():map("<leader>uh")
    if utils.enabled(group, "snacks_indent") then
      snacks.toggle.indent():map("<leader>ui")
    end
  end

  -- Rainbow palette for snacks.indent; re-applied on every colorscheme change
  if utils.enabled(group, "snacks_indent") then
    local function set_rainbow()
      vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75", default = true })
      vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379", default = true })
      vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66", default = true })
      vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF", default = true })
      vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B", default = true })
      vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD", default = true })
      vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2", default = true })
    end
    set_rainbow()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("lush_snacks_indent_rainbow", { clear = true }),
      callback = set_rainbow,
    })
  end
end
