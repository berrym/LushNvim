-- Eviline — the classic LushNvim default.
-- Original author: shadmansaleh. Credit: glepnir.

local M = {}

function M.setup()
  local utils = require("config.utils")
  local group = utils.get_plugin_group()
  local lualine = require("lualine")
  local get_attached_clients = utils.get_attached_clients

	-- stylua: ignore
	local colors = {
		bg       = "#202328",
		fg       = "#bbc2cf",
		yellow   = "#eCBe7B",
		cyan     = "#008080",
		darkblue = "#081633",
		green    = "#98be65",
		orange   = "#ff8800",
		violet   = "#a9a1e1",
		magenta  = "#c678dd",
		blue     = "#51afef",
		red      = "#ec5f67",
	}

  local conditions = {
    buffer_not_empty = function()
      return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
    end,
    hide_in_width = function()
      return vim.fn.winwidth(0) > 80
    end,
    check_git_workspace = function()
      local filepath = vim.fn.expand("%:p:h")
      local gitdir = vim.fn.finddir(".git", filepath .. ";")
      return gitdir and #gitdir > 0 and #gitdir < #filepath
    end,
  }

  local config = {
    options = {
      component_separators = "",
      section_separators = "",
      theme = {
        normal = { c = { fg = colors.fg, bg = colors.bg } },
        inactive = { c = { fg = colors.fg, bg = colors.bg } },
      },
    },
    sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_y = {},
      lualine_z = {},
      lualine_c = {},
      lualine_x = {},
    },
    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_y = {},
      lualine_z = {},
      lualine_c = {},
      lualine_x = {},
    },
  }

  local function ins_left(component)
    table.insert(config.sections.lualine_c, component)
  end
  local function ins_right(component)
    table.insert(config.sections.lualine_x, component)
  end

  ins_left({
    function()
      return "▊"
    end,
    color = { fg = colors.blue },
    padding = { left = 0, right = 1 },
  })

  ins_left({
    function()
      return ""
    end,
    color = function()
      local mode_color = {
        n = colors.red,
        i = colors.green,
        v = colors.blue,
        [""] = colors.blue,
        V = colors.blue,
        c = colors.magenta,
        no = colors.red,
        s = colors.orange,
        S = colors.orange,
        [""] = colors.orange,
        ic = colors.yellow,
        R = colors.violet,
        Rv = colors.violet,
        cv = colors.red,
        ce = colors.red,
        r = colors.cyan,
        rm = colors.cyan,
        ["r?"] = colors.cyan,
        ["!"] = colors.red,
        t = colors.red,
      }
      return { fg = mode_color[vim.fn.mode()] }
    end,
    padding = { right = 1 },
  })

  ins_left({ "filesize", cond = conditions.buffer_not_empty })
  ins_left({
    "filename",
    cond = conditions.buffer_not_empty,
    color = { fg = colors.magenta, gui = "bold" },
  })
  ins_left({ "location" })
  ins_left({ "progress", color = { fg = colors.fg, gui = "bold" } })
  ins_left({
    "diagnostics",
    sources = { "nvim_diagnostic" },
    symbols = { error = " ", warn = " ", info = " " },
    diagnostics_color = {
      error = { fg = colors.red },
      warn = { fg = colors.yellow },
      info = { fg = colors.cyan },
    },
  })

  if utils.enabled(group, "dap") then
    ins_left({
      function()
        local ok, dap = pcall(require, "dap")
        if not ok then
          return ""
        end
        local status = dap.status()
        return " " .. (status ~= "" and status or "Active")
      end,
      cond = function()
        local ok, dap = pcall(require, "dap")
        return ok and dap.session() ~= nil
      end,
      color = { fg = colors.orange, gui = "bold" },
    })
  end

  ins_left({
    function()
      return "%="
    end,
  })

  ins_right({
    function()
      return get_attached_clients()
    end,
    icon = " LSP:",
    color = { fg = "#ffffff", gui = "bold" },
  })

  ins_right({
    "o:encoding",
    fmt = string.upper,
    cond = conditions.hide_in_width,
    color = { fg = colors.green, gui = "bold" },
  })

  ins_right({
    "fileformat",
    fmt = string.upper,
    icons_enabled = false,
    color = { fg = colors.green, gui = "bold" },
  })

  ins_right({
    function()
      if vim.g.persisting then
        return "● session"
      end
      if vim.g.persisting == false then
        return "○ no session"
      end
      return ""
    end,
    cond = function()
      return vim.g.persisting ~= nil
    end,
    color = function()
      if vim.g.persisting then
        return { fg = colors.green }
      end
      return { fg = colors.yellow }
    end,
  })

  ins_right({ "branch", icon = "", color = { fg = colors.violet, gui = "bold" } })

  ins_right({
    "diff",
    symbols = { added = " ", modified = "󰝤 ", removed = " " },
    diff_color = {
      added = { fg = colors.green },
      modified = { fg = colors.orange },
      removed = { fg = colors.red },
    },
    cond = conditions.hide_in_width,
  })

  ins_right({
    function()
      return "▊"
    end,
    color = { fg = colors.blue },
    padding = { left = 1 },
  })

  lualine.setup(config)
end

return M
