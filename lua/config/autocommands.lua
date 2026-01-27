local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local exist, user_config = pcall(require, "user.config")
local group = exist and type(user_config) == "table" and user_config.autocommands or {}
local plugin = exist and type(user_config) == "table" and user_config.enable_plugins or {}
local enabled = require("config.utils").enabled

-- disables code folding for the start screen
if enabled(group, "alpha_folding") then
  autocmd({ "FileType" }, {
    desc = "Disable folding for alpha buffer",
    group = augroup("alpha", { clear = true }),
    pattern = "alpha",
    command = "setlocal nofoldenable",
  })
end

-- Removes any trailing whitespace when saving a file
if enabled(group, "whitespace_cleanup") then
  autocmd({ "BufWritePre" }, {
    desc = "remove trailing whitespace on save",
    group = augroup("remove trailing whitespace", { clear = true }),
    pattern = { "*" },
    command = [[%s/\s\+$//e]],
  })
end

-- remembers file state, such as cursor position and any folds
if enabled(group, "remember_file_state") then
  augroup("remember file state", { clear = true })
  autocmd({ "BufWinLeave" }, {
    desc = "remember file state",
    group = "remember file state",
    pattern = { "*.*" },
    command = "mkview",
  })
  autocmd({ "BufWinEnter" }, {
    desc = "remember file state",
    group = "remember file state",
    pattern = { "*.*" },
    command = "silent! loadview",
  })
end

-- gives you a notification upon saving a session
if enabled(group, "session_saved_notification") then
  autocmd({ "User" }, {
    desc = "notify session saved",
    group = augroup("session save", { clear = true }),
    pattern = "SessionSavePost",
    command = "lua require('config.utils').notify_info('Session Saved')",
  })
end

-- enables coloring hexcodes and color names in css, jsx, etc.
if enabled(group, "css_colorizer") and enabled(plugin, "colorizer") then
  autocmd({ "Filetype" }, {
    desc = "activate colorizer",
    pattern = "css,scss,html,xml,svg,js,jsx,ts,tsx,php,vue",
    group = augroup("colorizer", { clear = true }),
    callback = function()
      require("colorizer").attach_to_buffer(0, {
        mode = "background",
        css = true,
      })
    end,
  })
end

-- disables autocomplete in some filetypes
if enabled(group, "cmp") and enabled(plugin, "cmp") then
  autocmd({ "FileType" }, {
    desc = "disable cmp in certain filetypes",
    pattern = "gitcommit,gitrebase,text",
    group = augroup("cmp_disable", { clear = true }),
    command = "lua require('cmp').setup.buffer { enabled = false}",
  })
end

-- fixes Trouble not closing when last window in tab
autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("TroubleClose", { clear = true }),
  callback = function()
    local layout = vim.api.nvim_call_function("winlayout", {})
    if
        layout[1] == "leaf"
        and vim.api.nvim_get_option_value("filetype", { buf = vim.api.nvim_win_get_buf(layout[2]) }) == type(
          "Trouble"
        )
        and layout[3] == nil
    then
      vim.cmd("confirm quit")
    end
  end,
})

-- Set indentation to 2 spaces based on filetype
autocmd("Filetype", {
  group = augroup("setIndent2", { clear = true }),
  pattern = {
    "lua",
    "css",
    "html",
    "javascript",
    "typescript",
    "scss",
    "xml",
    "xhtml",
    "yaml",
    "ruby",
  },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})

-- Set indentation to 4 spaces based on filetype
autocmd("Filetype", {
  group = augroup("setIndent4", { clear = true }),
  pattern = {
    "c",
    "cpp",
    "obj",
    "objcpp",
    "cuda",
    "proto",
    "python",
    "rust",
    "go",
    "markdown",
    "md",
    "toml",
    "java",
  },
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
  end,
})

-- Replace autochdir
autocmd("BufWinEnter", {
  group = augroup("autochdir", { clear = true }),
  pattern = "*",
  callback = function()
    local ignoredFT = {
      "gitcommit",
      "NeogitCommitMessage",
      "DiffviewFileHistory",
      "",
    }
    if
        not vim.bo.modifiable
        or vim.tbl_contains(ignoredFT, vim.bo.filetype)
        or not (vim.fn.expand("%:p"):find("^/"))
    then
      return
    end
    vim.cmd.cd(vim.fn.expand("%:p:h"))
  end,
})
