local exist, user_config = pcall(require, "user.config")
local group = exist and type(user_config) == "table" and user_config.enable_plugins or {}
local enabled = require("config.utils").enabled

if enabled(group, "whichkey") then
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
    { "<leader>n", group = "Explorer", icon = "󰙅" },
    { "<leader>q", group = "Quit", icon = "󰗼" },
    { "<leader>s", group = "Session", icon = "󱂬" },
    { "<leader>t", group = "Tab", icon = "󰓩" },
    { "<leader>u", group = "UI", icon = "" },
    { "<leader>w", group = "Window", icon = "" },
    { "<leader>x", group = "Diagnostics", icon = "󰒡" },
    { "<leader>ad", group = "+Diff", icon = "" },
  })
end
