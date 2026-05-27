local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "snacks") then
  local ok, snacks = pcall(require, "snacks")
  if ok then
    -- Re-apply opts on reload so toggling enable_plugins.snacks_<module>
    -- and running :LushReload actually flips the module. lazy.nvim ran
    -- snacks.setup with the initial opts at startup; this call refreshes
    -- with the current enable_plugins values.
    local ok_opts, snacks_opts = pcall(require, "lush.snacks_opts")
    if ok_opts then
      pcall(snacks.setup, snacks_opts.build())
    end

    -- Toggle mappings using snacks.toggle. snacks binds these via its own
    -- :map(lhs) helper, so we explicitly register each with the LushNvim
    -- keymap registry so :LushReload can clear them when snacks is disabled.
    local toggles = {
      { "<leader>us", snacks.toggle.option("spell", { name = "Spelling" }) },
      { "<leader>uw", snacks.toggle.option("wrap", { name = "Wrap" }) },
      { "<leader>uL", snacks.toggle.option("relativenumber", { name = "Relative Number" }) },
      -- uN because lowercase ul is the LushStatusline picker
      { "<leader>uN", snacks.toggle.line_number() },
      { "<leader>ud", snacks.toggle.diagnostics() },
      -- NOTE: uppercase uC because lowercase uc is the LushColors picker.
      {
        "<leader>uC",
        snacks.toggle.option(
          "conceallevel",
          { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }
        ),
      },
      { "<leader>uT", snacks.toggle.treesitter() },
      { "<leader>uh", snacks.toggle.inlay_hints() },
    }
    if utils.enabled(group, "snacks_indent") then
      table.insert(toggles, { "<leader>ui", snacks.toggle.indent() })
    end
    for _, t in ipairs(toggles) do
      t[2]:map(t[1])
      utils.track_keymap("n", t[1])
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
