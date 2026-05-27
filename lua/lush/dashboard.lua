-- LushNvim dashboard config for snacks.dashboard.
-- Buttons, header, and footer are built dynamically from user enable_plugins
-- and current repo state, mirroring the layout the previous alpha config had.

local M = {}

M.header = [[
██╗     ██╗   ██╗███████╗██╗  ██╗    ███╗   ██╗██╗   ██╗██╗███╗   ███╗
██║     ██║   ██║██╔════╝██║  ██║    ████╗  ██║██║   ██║██║████╗ ████║
██║     ██║   ██║███████╗███████║    ██╔██╗ ██║██║   ██║██║██╔████╔██║
██║     ██║   ██║╚════██║██╔══██║    ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║
███████╗╚██████╔╝███████║██║  ██║    ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║
╚══════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝    ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝]]

function M.keys()
  local utils = require("config.utils")
  local group = utils.get_plugin_group()

  local items = {
    { icon = " ", key = "f", desc = "Find file", action = ":Telescope find_files" },
    {
      icon = " ",
      key = "n",
      desc = "New file",
      action = ":lua require('config.utils').create_new_file()",
    },
    { icon = " ", key = "b", desc = "New buffer", action = ":ene!" },
    { icon = " ", key = "r", desc = "Recent files", action = ":Telescope oldfiles" },
    { icon = "󱎸 ", key = "t", desc = "Find text", action = ":Telescope live_grep" },
  }

  if utils.is_git_repo() then
    table.insert(
      items,
      { icon = "󰊢 ", key = "g", desc = "Find file in git repo", action = ":Telescope git_files" }
    )
  end

  if utils.enabled(group, "session_manager") then
    table.insert(items, {
      icon = "󱀸 ",
      key = "l",
      desc = "Resume last session",
      action = ":lua require('persisted').load({ last = true })",
    })
    table.insert(
      items,
      { icon = " ", key = "o", desc = "Browse sessions", action = ":Telescope persisted" }
    )
  end

  if utils.enabled(group, "project") then
    table.insert(
      items,
      { icon = " ", key = "p", desc = "Open project", action = ":lua telescope_open_project()" }
    )
  end

  table.insert(
    items,
    { icon = "󰋽 ", key = "h", desc = "Health check", action = ":checkhealth lush" }
  )
  table.insert(items, { icon = "󰩈 ", key = "q", desc = "Quit", action = ":qa" })

  return items
end

M.footer = table.concat({
  "Config: lua/user/config.lua",
  "",
  "Leader: SPC  a=AI b=Buf c=Code d=Debug f=Find g=Git",
  "        n=Explorer q=Quit s=Session t=Tab u=UI w=Win x=Diag",
}, "\n")

function M.opts(is_enabled)
  if not is_enabled then
    return { enabled = false }
  end
  return {
    enabled = true,
    preset = {
      header = M.header,
      keys = M.keys(),
    },
    sections = {
      { section = "header" },
      { section = "keys", gap = 1, padding = 1 },
      { text = M.footer, align = "center", padding = 1 },
      { section = "startup" },
    },
  }
end

return M
