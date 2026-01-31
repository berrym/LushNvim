local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "whichkey") then
  local wk = require("which-key")

  wk.setup({
    preset = "modern",
    delay = 300,
    icons = { mappings = true },
    win = { border = "rounded" },
  })

  wk.add({
    { "<leader>a", group = "AI/Claude", icon = "󰚩" },
    { "<leader>b", group = "Buffer", icon = "󰈔" },
    { "<leader>c", group = "Code/LSP", icon = "" },
    { "<leader>d", group = "Debug", icon = "" },
    { "<leader>f", group = "Find", icon = "" },
    { "<leader>g", group = "Git", icon = "" },
    { "<leader>G", group = "Go", icon = "" },
    { "<leader>C", group = "C/C++", icon = "" },
    { "<leader>n", group = "Explorer", icon = "󰙅" },
    { "<leader>q", group = "Quit", icon = "󰗼" },
    { "<leader>s", group = "Session", icon = "󱂬" },
    { "<leader>t", group = "Tab", icon = "󰓩" },
    { "<leader>u", group = "UI", icon = "" },
    { "<leader>w", group = "Window", icon = "" },
    { "<leader>x", group = "Diagnostics", icon = "󰒡" },
    { "<leader>ad", group = "+Diff", icon = "" },
    { "<leader>aw", group = "+Window", icon = "" },
    { "<leader>r", group = "Rust", icon = "🦀" },
    { "<leader>p", group = "Python", icon = "🐍" },
  })

end
