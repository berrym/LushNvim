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

-- ══════════════════════════════════════════════════════════════════════════════
-- Layout Helpers (used by multiple autocommands below)
-- ══════════════════════════════════════════════════════════════════════════════

local sidebar_filetypes = {
  ["neo-tree"] = true, ["Trouble"] = true, ["qf"] = true, ["help"] = true,
  ["toggleterm"] = true, ["dapui_scopes"] = true, ["dapui_breakpoints"] = true,
  ["dapui_stacks"] = true, ["dapui_watches"] = true, ["dapui_console"] = true,
  ["dap-repl"] = true,
}

local function is_sidebar_win(win)
  if not vim.api.nvim_win_is_valid(win) then return true end
  local cfg = vim.api.nvim_win_get_config(win)
  if cfg.relative and cfg.relative ~= "" then return true end
  local buf = vim.api.nvim_win_get_buf(win)
  return vim.bo[buf].buftype == "terminal" or sidebar_filetypes[vim.bo[buf].filetype] or false
end

-- Find or create a single reusable scratch buffer (prevents [No Name] proliferation)
local function get_scratch_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf)
        and vim.api.nvim_buf_get_name(buf) == ""
        and not vim.bo[buf].modified
        and vim.bo[buf].buftype == ""
        and vim.bo[buf].buflisted then
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      if #lines <= 1 and (lines[1] or "") == "" then
        return buf
      end
    end
  end
  return vim.api.nvim_create_buf(true, false)
end

local function count_real_wins()
  local n = 0
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if not is_sidebar_win(win) then n = n + 1 end
  end
  return n
end

local function ensure_editor_window()
  if count_real_wins() > 0 then return end
  local wins = vim.api.nvim_tabpage_list_wins(0)
  if #wins == 0 then return end
  -- Prefer non-neo-tree, non-floating window to show scratch
  for _, win in ipairs(wins) do
    if vim.api.nvim_win_is_valid(win) then
      local cfg = vim.api.nvim_win_get_config(win)
      if (not cfg.relative or cfg.relative == "")
          and vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "neo-tree" then
        vim.api.nvim_win_set_buf(win, get_scratch_buf())
        return
      end
    end
  end
  -- Fallback: split from first available non-floating window
  for _, win in ipairs(wins) do
    if vim.api.nvim_win_is_valid(win) then
      local cfg = vim.api.nvim_win_get_config(win)
      if not cfg.relative or cfg.relative == "" then
        vim.api.nvim_set_current_win(win)
        vim.cmd("vsplit")
        vim.api.nvim_win_set_buf(0, get_scratch_buf())
        return
      end
    end
  end
end

-- Trouble: close and show scratch instead of quitting nvim
autocmd("BufEnter", {
  group = augroup("TroubleClose", { clear = true }),
  callback = function()
    local layout = vim.fn.winlayout()
    if
        layout[1] == "leaf"
        and vim.bo[vim.api.nvim_win_get_buf(layout[2])].filetype == "Trouble"
        and layout[3] == nil
    then
      vim.schedule(function()
        pcall(vim.cmd, "Trouble close")
        ensure_editor_window()
      end)
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
  pattern = vim.iter(vim.tbl_values(indent_config)):flatten():totable(),
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

-- ══════════════════════════════════════════════════════════════════════════════
-- Layout Guardian: prevent sidebar-only layouts when last editor window closes
-- ══════════════════════════════════════════════════════════════════════════════

autocmd("WinClosed", {
  group = augroup("layout_guardian", { clear = true }),
  callback = function()
    vim.schedule(ensure_editor_window)
  end,
})

-- Prevent nvim from quitting when closing the last editor window (sidebars remain)
autocmd("QuitPre", {
  group = augroup("quit_guardian", { clear = true }),
  callback = function()
    -- If only one real window remains, create a scratch buffer split so :q
    -- closes just that window rather than terminating nvim entirely
    if count_real_wins() <= 1 then
      local sidebar_count = 0
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if is_sidebar_win(win) then sidebar_count = sidebar_count + 1 end
      end
      if sidebar_count > 0 then
        vim.cmd("vsplit")
        vim.api.nvim_win_set_buf(0, get_scratch_buf())
      end
    end
  end,
})

-- ══════════════════════════════════════════════════════════════════════════════
-- Diff Mode Layout Management + Claude Diff Cleanup
-- ══════════════════════════════════════════════════════════════════════════════

local _neotree_was_open = false
local _had_diff_activity = false

local function neotree_is_visible()
  local ok, manager = pcall(require, "neo-tree.sources.manager")
  if not ok then return false end
  local ok2, state = pcall(manager.get_state, "filesystem")
  if not ok2 or not state then return false end
  return state.winid and vim.api.nvim_win_is_valid(state.winid)
end

local function any_diff_windows()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) and vim.wo[win].diff then
      return true
    end
  end
  return false
end

local function is_claude_diff_buf(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return false end
  local ok, val = pcall(vim.api.nvim_buf_get_var, buf, "claudecode_diff_tab_name")
  return ok and val ~= nil
end

local function has_claude_diff_bufs()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if is_claude_diff_buf(buf) and vim.api.nvim_buf_is_loaded(buf) then
      return true
    end
  end
  return false
end

local function diff_cleanup()
  if not _had_diff_activity then return end
  -- Still in an active diff — don't clean up yet
  if any_diff_windows() then return end
  -- No Claude diff buffers to clean — nothing to do
  if not has_claude_diff_bufs() then
    _had_diff_activity = false
    return
  end

  _had_diff_activity = false

  -- Delete stale Claude diff buffers
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if is_claude_diff_buf(buf) and vim.api.nvim_buf_is_loaded(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end

  -- Turn off diff mode on any remaining windows
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) and vim.wo[win].diff then
      vim.api.nvim_win_call(win, function() vim.cmd("diffoff") end)
    end
  end

  -- Close windows holding empty unnamed buffers left over from diff teardown
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) and not is_sidebar_win(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_get_name(buf) == ""
          and vim.bo[buf].buftype == ""
          and not vim.bo[buf].modified then
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        if #lines <= 1 and (lines[1] or "") == "" then
          -- Only close if there are other real windows remaining
          if count_real_wins() > 1 then
            pcall(vim.api.nvim_win_close, win, true)
          end
        end
      end
    end
  end

  -- Ensure we have at least one real editor window
  ensure_editor_window()

  -- Restore neo-tree if it was open before the diff
  if _neotree_was_open then
    _neotree_was_open = false
    pcall(vim.cmd, "Neotree show left")
  end
end

-- Entering diff mode: only close neo-tree for space (do NOT close/manipulate other windows)
autocmd("OptionSet", {
  group = augroup("diff_layout", { clear = true }),
  pattern = "diff",
  callback = function()
    -- Only trigger when diff is being turned ON
    if not vim.v.option_new or vim.v.option_new == false or vim.v.option_new == "0" then return end
    _had_diff_activity = true
    -- Close neo-tree to give diff maximum space
    if neotree_is_visible() then
      _neotree_was_open = true
      pcall(vim.cmd, "Neotree close")
    end
  end,
})

-- Exiting diff mode: clean up when diff windows close
autocmd("WinClosed", {
  group = augroup("diff_cleanup_winclosed", { clear = true }),
  callback = function()
    if not _had_diff_activity then return end
    vim.schedule(diff_cleanup)
  end,
})

-- Safety net: catch async plugin cleanup that doesn't fire WinClosed
autocmd("BufEnter", {
  group = augroup("diff_cleanup_bufenter", { clear = true }),
  callback = function()
    if not _had_diff_activity then return end
    -- Never trigger cleanup when entering a terminal buffer (e.g. Claude terminal)
    if vim.bo.buftype == "terminal" then return end
    vim.schedule(diff_cleanup)
  end,
})
