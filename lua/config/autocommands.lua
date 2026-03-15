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

local sidebar_filetypes = {
  ["neo-tree"] = true,
  ["Trouble"] = true,
  ["qf"] = true,
  ["help"] = true,
  ["toggleterm"] = true,
  ["dapui_scopes"] = true,
  ["dapui_breakpoints"] = true,
  ["dapui_stacks"] = true,
  ["dapui_watches"] = true,
  ["dapui_console"] = true,
  ["dap-repl"] = true,
}

local function is_sidebar_win(win)
  if not vim.api.nvim_win_is_valid(win) then return true end
  local cfg = vim.api.nvim_win_get_config(win)
  if cfg.relative and cfg.relative ~= "" then return true end
  local buf = vim.api.nvim_win_get_buf(win)
  local bt = vim.bo[buf].buftype
  local ft = vim.bo[buf].filetype
  return bt == "terminal" or sidebar_filetypes[ft] or false
end

autocmd("WinClosed", {
  group = augroup("layout_guardian", { clear = true }),
  callback = function()
    vim.schedule(function()
      local wins = vim.api.nvim_tabpage_list_wins(0)
      local real_wins = 0
      local first_sidebar = nil
      for _, win in ipairs(wins) do
        if not is_sidebar_win(win) then
          real_wins = real_wins + 1
        elseif not first_sidebar then
          first_sidebar = win
        end
      end
      if real_wins == 0 and #wins > 0 then
        -- Find a non-floating window to put the scratch buffer in
        for _, win in ipairs(wins) do
          local cfg = vim.api.nvim_win_get_config(win)
          if not cfg.relative or cfg.relative == "" then
            local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
            if ft ~= "neo-tree" then
              vim.api.nvim_set_current_win(win)
              vim.cmd("enew")
              return
            end
          end
        end
        -- Fallback: use any non-floating window
        if first_sidebar then
          vim.api.nvim_set_current_win(first_sidebar)
          vim.cmd("enew")
        end
      end
    end)
  end,
})

-- ══════════════════════════════════════════════════════════════════════════════
-- Diff Mode Layout Management + Claude Diff Cleanup
-- ══════════════════════════════════════════════════════════════════════════════

local _pre_diff_state = nil   -- saved {win, buf} pairs before diff
local _neotree_was_open = false
local _in_diff_mode = false

-- Check if neo-tree has a visible window in the current tab
local function neotree_is_visible()
  local ok, manager = pcall(require, "neo-tree.sources.manager")
  if not ok then return false end
  local ok2, state = pcall(manager.get_state, "filesystem")
  if not ok2 or not state then return false end
  return state.winid and vim.api.nvim_win_is_valid(state.winid)
end

-- Check if any window in the current tab has diff mode active
local function any_diff_windows()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) and vim.wo[win].diff then
      return true
    end
  end
  return false
end

-- Check if a buffer is a Claude diff buffer
local function is_claude_diff_buf(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return false end
  local ok, val = pcall(vim.api.nvim_buf_get_var, buf, "claudecode_diff_tab_name")
  return ok and val ~= nil
end

-- Clean up stale Claude diff buffers and restore layout
local function diff_cleanup()
  if not _in_diff_mode then return end
  if any_diff_windows() then return end

  -- No diff windows remain — clean up
  _in_diff_mode = false

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

  -- Restore previous layout
  if _pre_diff_state and #_pre_diff_state > 0 then
    -- Close all non-terminal, non-sidebar windows first
    local wins = vim.api.nvim_tabpage_list_wins(0)
    for _, win in ipairs(wins) do
      if vim.api.nvim_win_is_valid(win) and not is_sidebar_win(win) then
        local buf = vim.api.nvim_win_get_buf(win)
        -- Keep window if its buffer was in our saved state
        local dominated = true
        for _, saved in ipairs(_pre_diff_state) do
          if saved.buf == buf then
            dominated = false
            break
          end
        end
        if dominated then
          pcall(vim.api.nvim_win_close, win, true)
        end
      end
    end

    -- Ensure at least one window has a saved buffer
    local current_wins = vim.api.nvim_tabpage_list_wins(0)
    local has_real = false
    for _, win in ipairs(current_wins) do
      if not is_sidebar_win(win) then
        has_real = true
        break
      end
    end

    if not has_real then
      -- Open the first saved buffer
      for _, win in ipairs(current_wins) do
        local cfg = vim.api.nvim_win_get_config(win)
        if (not cfg.relative or cfg.relative == "") then
          vim.api.nvim_set_current_win(win)
          break
        end
      end
      if _pre_diff_state[1] and vim.api.nvim_buf_is_valid(_pre_diff_state[1].buf) then
        vim.api.nvim_set_current_buf(_pre_diff_state[1].buf)
      else
        vim.cmd("enew")
      end
    end

    -- Open additional saved buffers in splits if there were multiple
    for i = 2, #_pre_diff_state do
      local saved = _pre_diff_state[i]
      if vim.api.nvim_buf_is_valid(saved.buf) then
        vim.cmd("vsplit")
        vim.api.nvim_set_current_buf(saved.buf)
      end
    end
  end

  -- Restore neo-tree if it was open
  if _neotree_was_open then
    _neotree_was_open = false
    pcall(vim.cmd, "Neotree show left")
  end

  _pre_diff_state = nil
end

-- Entering diff mode: save state and maximize diff space
autocmd("OptionSet", {
  group = augroup("diff_layout", { clear = true }),
  pattern = "diff",
  callback = function()
    if _in_diff_mode then return end
    -- Only trigger when diff is being turned ON
    if not vim.v.option_new or vim.v.option_new == false or vim.v.option_new == "0" then return end

    _in_diff_mode = true

    -- Save current layout (non-sidebar, non-diff windows and their buffers)
    _pre_diff_state = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_is_valid(win) and not is_sidebar_win(win) then
        local buf = vim.api.nvim_win_get_buf(win)
        if not vim.wo[win].diff then
          table.insert(_pre_diff_state, { win = win, buf = buf })
        end
      end
    end

    -- Close neo-tree to give diff maximum space
    if neotree_is_visible() then
      _neotree_was_open = true
      pcall(vim.cmd, "Neotree close")
    end

    -- Close non-diff, non-terminal editor windows to give diffs full space
    vim.schedule(function()
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_is_valid(win)
            and not is_sidebar_win(win)
            and not vim.wo[win].diff then
          pcall(vim.api.nvim_win_close, win, false)
        end
      end
    end)
  end,
})

-- Exiting diff mode: clean up and restore
autocmd("WinClosed", {
  group = augroup("diff_cleanup_winclosed", { clear = true }),
  callback = function()
    if not _in_diff_mode then return end
    vim.schedule(diff_cleanup)
  end,
})

-- Safety net: catch cases where WinClosed doesn't fire (async plugin cleanup)
autocmd("BufEnter", {
  group = augroup("diff_cleanup_bufenter", { clear = true }),
  callback = function()
    if not _in_diff_mode then return end
    vim.schedule(diff_cleanup)
  end,
})
