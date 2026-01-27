local exist, user_config = pcall(require, "user.config")
local group = exist and type(user_config) == "table" and user_config.enable_plugins or {}
local enabled = require("config.utils").enabled
local dashboard = require("alpha.themes.dashboard")

if enabled(group, "alpha") then
  dashboard.section.header.val = {
    "██╗     ██╗   ██╗███████╗██╗  ██╗    ███╗   ██╗██╗   ██╗██╗███╗   ███╗",
    "██║     ██║   ██║██╔════╝██║  ██║    ████╗  ██║██║   ██║██║████╗ ████║",
    "██║     ██║   ██║███████╗███████║    ██╔██╗ ██║██║   ██║██║██╔████╔██║",
    "██║     ██║   ██║╚════██║██╔══██║    ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║",
    "███████╗╚██████╔╝███████║██║  ██║    ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║",
    "╚══════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝    ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝",

    -- "██╗     ██╗   ██╗███████╗██╗   ██╗███████╗    ███╗   ██╗██╗   ██╗██╗███╗   ███╗",
    -- "██║     ██║   ██║██╔════╝██║   ██║██╔════╝    ████╗  ██║██║   ██║██║████╗ ████║",
    -- "██║     ██║   ██║███████╗██║   ██║███████╗    ██╔██╗ ██║██║   ██║██║██╔████╔██║",
    -- "██║     ██║   ██║╚════██║██║   ██║╚════██║    ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║",
    -- "███████╗╚██████╔╝███████║╚██████╔╝███████║    ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║",
    -- "╚══════╝ ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝    ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝",
  }

  local buttons = {
    dashboard.button("f", "  Find file", ":Telescope find_files<CR>"),
    dashboard.button("n", "  New file", ":lua require('config.utils').create_new_file()<CR>"),
    dashboard.button("b", "  New buffer", ":ene!<CR>"),
    dashboard.button("r", "  Recent", ":Telescope oldfiles<CR>"),
    dashboard.button("t", "󱎸  Find text", ":Telescope live_grep<CR>"),
  }

  if require("config.utils").is_git_repo() then
    table.insert(
      buttons,
      dashboard.button("g", "󰊢  Find file in git repo", ":Telescope git_files<CR>")
    )
  end

  if enabled(group, "session_manager") then
    table.insert(
      buttons,
      dashboard.button("l", "󱀸  Open last session", ":SessionManager load_last_session<CR>")
    )
    table.insert(
      buttons,
      dashboard.button("o", "  Open session", ":SessionManager load_session<CR>")
    )
  end

  if enabled(group, "project") then
    table.insert(buttons, dashboard.button("p", "  Open project", ":Telescope projects<CR>"))
  end

  table.insert(buttons, dashboard.button("q", "󰩈  Quit", ":qall<CR>"))

  dashboard.section.buttons.val = buttons

  local fortune = require("alpha.fortune")
  dashboard.section.footer.val = fortune()

  require("alpha").setup(dashboard.opts)
end
