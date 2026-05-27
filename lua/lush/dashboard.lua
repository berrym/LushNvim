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

-- Nerd-font icons written as raw UTF-8 byte escapes so the Write tool (and
-- other editors that strip PUA glyphs) can't blank them out. Codepoints
-- mirror the alpha-nvim dashboard set this replaced.
local icons = {
  find_file = "\xef\x80\x82 ", -- U+F002 magnifying glass
  new_file = "\xef\x85\x9b ", -- U+F15B file
  new_buffer = "\xef\x85\x9c ", -- U+F15C file-text
  recent = "\xef\x87\x9a ", -- U+F1DA history
  find_text = "\xf3\xb1\x8e\xb8 ", -- U+F1BB8 magnify scan
  git_files = "\xf3\xb0\x8a\xa2 ", -- U+F0AA2 git
  last_session = "\xf3\xb1\x80\xb8 ", -- U+F1078 restore
  browse_sessions = "\xef\x81\xbc ", -- U+F07C folder-open
  open_project = "\xef\x94\x83 ", -- U+F503 folder-multiple
  health = "\xf3\xb0\x8b\xbd ", -- U+F02FD information
  quit = "\xf3\xb0\xa9\x88 ", -- U+F0A48 power
}

function M.keys()
  local utils = require("config.utils")
  local group = utils.get_plugin_group()

  local items = {
    { icon = icons.find_file, key = "f", desc = "Find file", action = ":Telescope find_files" },
    {
      icon = icons.new_file,
      key = "n",
      desc = "New file",
      action = ":lua require('config.utils').create_new_file()",
    },
    { icon = icons.new_buffer, key = "b", desc = "New buffer", action = ":ene!" },
    { icon = icons.recent, key = "r", desc = "Recent files", action = ":Telescope oldfiles" },
    { icon = icons.find_text, key = "t", desc = "Find text", action = ":Telescope live_grep" },
  }

  if utils.is_git_repo() then
    table.insert(items, {
      icon = icons.git_files,
      key = "g",
      desc = "Find file in git repo",
      action = ":Telescope git_files",
    })
  end

  if utils.enabled(group, "session_manager") then
    table.insert(items, {
      icon = icons.last_session,
      key = "l",
      desc = "Resume last session",
      action = ":lua require('persisted').load({ last = true })",
    })
    table.insert(items, {
      icon = icons.browse_sessions,
      key = "o",
      desc = "Browse sessions",
      action = ":Telescope persisted",
    })
  end

  if utils.enabled(group, "project") then
    table.insert(items, {
      icon = icons.open_project,
      key = "p",
      desc = "Open project",
      action = ":lua telescope_open_project()",
    })
  end

  table.insert(
    items,
    { icon = icons.health, key = "h", desc = "Health check", action = ":checkhealth lush" }
  )
  table.insert(items, { icon = icons.quit, key = "q", desc = "Quit", action = ":qa" })

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
