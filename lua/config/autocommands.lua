local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local utils = require("config.utils")
local user_config = utils.get_user_config()
local group = user_config.autocommands or {}
local plugin = user_config.enable_plugins or {}

-- Clear stale search highlights on startup (from shada/session restore)
autocmd("VimEnter", {
  group = augroup("clear_hlsearch", { clear = true }),
  callback = function()
    vim.cmd.nohlsearch()
  end,
})

-- disables code folding for the start screen
if utils.enabled(group, "alpha_folding") then
  autocmd("FileType", {
    desc = "Disable folding for alpha buffer",
    group = augroup("alpha", { clear = true }),
    pattern = "alpha",
    command = "setlocal nofoldenable",
  })
end

-- Removes any trailing whitespace when saving a file
if utils.enabled(group, "whitespace_cleanup") then
  autocmd("BufWritePre", {
    desc = "remove trailing whitespace on save",
    group = augroup("remove trailing whitespace", { clear = true }),
    pattern = "*",
    command = [[%s/\s\+$//e]],
  })
end

-- remembers file state, such as cursor position and any folds
if utils.enabled(group, "remember_file_state") then
  local remember_group = augroup("remember file state", { clear = true })
  autocmd("BufWinLeave", {
    desc = "remember file state",
    group = remember_group,
    pattern = "*.*",
    command = "mkview",
  })
  autocmd("BufWinEnter", {
    desc = "remember file state",
    group = remember_group,
    pattern = "*.*",
    command = "silent! loadview",
  })
end

-- gives you a notification upon saving a session
if utils.enabled(group, "session_saved_notification") then
  autocmd("User", {
    desc = "notify session saved",
    group = augroup("session save", { clear = true }),
    pattern = "SessionSavePost",
    callback = function()
      utils.notify_info("Session Saved")
    end,
  })
end

-- enables coloring hexcodes and color names in css, jsx, etc.
if utils.enabled(group, "css_colorizer") and utils.enabled(plugin, "colorizer") then
  autocmd("FileType", {
    desc = "activate colorizer",
    pattern = { "css", "scss", "html", "xml", "svg", "js", "jsx", "ts", "tsx", "php", "vue" },
    group = augroup("colorizer", { clear = true }),
    callback = function()
      require("colorizer").attach_to_buffer(0, {
        mode = "background",
        css = true,
      })
    end,
  })
end

-- disables autocomplete in some filetypes (blink.cmp)
if utils.enabled(group, "cmp") and utils.enabled(plugin, "cmp") then
  autocmd("FileType", {
    desc = "disable completion in certain filetypes",
    pattern = { "gitcommit", "gitrebase", "text" },
    group = augroup("cmp_disable", { clear = true }),
    callback = function()
      vim.b.completion = false
    end,
  })
end

-- fixes Trouble not closing when last window in tab
autocmd("BufEnter", {
  group = augroup("TroubleClose", { clear = true }),
  callback = function()
    local layout = vim.fn.winlayout()
    if
        layout[1] == "leaf"
        and vim.bo[vim.api.nvim_win_get_buf(layout[2])].filetype == "Trouble"
        and layout[3] == nil
    then
      vim.cmd.confirm("quit")
    end
  end,
})

-- Filetype-specific indentation settings
local indent_config = {
  [2] = { "lua", "css", "html", "javascript", "typescript", "scss", "xml", "xhtml", "yaml", "ruby" },
  [4] = { "c", "cpp", "obj", "objcpp", "cuda", "proto", "python", "rust", "go", "markdown", "md", "toml", "java" },
}

autocmd("FileType", {
  group = augroup("setIndent", { clear = true }),
  pattern = vim.tbl_flatten(vim.tbl_values(indent_config)),
  callback = function()
    local ft = vim.bo.filetype
    for width, filetypes in pairs(indent_config) do
      if vim.tbl_contains(filetypes, ft) then
        vim.opt_local.shiftwidth = width
        vim.opt_local.tabstop = width
        vim.opt_local.softtabstop = width
        vim.opt_local.expandtab = true
        return
      end
    end
  end,
})

-- Auto-reload buffers when files change externally
if utils.enabled(group, "auto_reload") then
  local auto_reload_group = augroup("auto_reload", { clear = true })
  autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
    desc = "Check for external file changes",
    group = auto_reload_group,
    pattern = "*",
    callback = function()
      if vim.fn.getcmdwintype() == "" then
        vim.cmd("checktime")
      end
    end,
  })
  autocmd("FileChangedShellPost", {
    desc = "Notify when file changed externally",
    group = auto_reload_group,
    pattern = "*",
    callback = function()
      utils.notify_warn("File changed on disk. Buffer reloaded.", "File Changed")
    end,
  })
end

-- Claude Code auto-reload (more aggressive, for AI-edited files)
if utils.enabled(group, "claude_code_reload") then
  autocmd({ "FocusGained", "BufEnter" }, {
    desc = "Reload buffers when Claude Code edits files",
    group = augroup("claude_code_reload", { clear = true }),
    pattern = "*",
    callback = function()
      if vim.fn.getcmdwintype() == "" and vim.bo.buftype == "" then
        vim.cmd("checktime")
      end
    end,
  })
end

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
        vim.bo.buftype ~= ""
        or not vim.bo.modifiable
        or vim.tbl_contains(ignoredFT, vim.bo.filetype)
        or not (vim.fn.expand("%:p"):find("^/"))
    then
      return
    end

    -- Prefer project root (from project.nvim) over raw file directory
    local filepath = vim.fn.expand("%:p")
    local dir
    local ok, project = pcall(require, "project_nvim.project")
    if ok then
      local root = project.get_project_root()
      if root and filepath:find(root, 1, true) == 1 then
        dir = root
      end
    end
    if not dir then
      dir = vim.fn.expand("%:p:h")
    end
    vim.cmd.cd(vim.fn.fnameescape(dir))
  end,
})
