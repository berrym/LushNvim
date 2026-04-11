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
    pattern = "PersistedSavePost",
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

local _ensuring_editor = false
local function ensure_editor_window()
  if _ensuring_editor then return end
  if count_real_wins() > 0 then return end
  _ensuring_editor = true
  local wins = vim.api.nvim_tabpage_list_wins(0)
  if #wins == 0 then
    _ensuring_editor = false
    return
  end
  -- Prefer non-floating, non-neo-tree, non-terminal window to show scratch
  for _, win in ipairs(wins) do
    if vim.api.nvim_win_is_valid(win) then
      local cfg = vim.api.nvim_win_get_config(win)
      if (not cfg.relative or cfg.relative == "") then
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype ~= "neo-tree" and vim.bo[buf].buftype ~= "terminal" then
          vim.api.nvim_win_set_buf(win, get_scratch_buf())
          _ensuring_editor = false
          return
        end
      end
    end
  end
  -- Fallback: split from first available non-floating window (creates new window)
  for _, win in ipairs(wins) do
    if vim.api.nvim_win_is_valid(win) then
      local cfg = vim.api.nvim_win_get_config(win)
      if not cfg.relative or cfg.relative == "" then
        vim.api.nvim_set_current_win(win)
        vim.cmd("botright vsplit")
        vim.api.nvim_win_set_buf(0, get_scratch_buf())
        _ensuring_editor = false
        return
      end
    end
  end
  _ensuring_editor = false
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

    -- Prefer project root (via vim.fs.root) over raw file directory
    local filepath = vim.fn.expand("%:p")
    local root = vim.fs.root(0, {
      ".git",
      "Makefile", "CMakeLists.txt", "meson.build",
      "Cargo.toml",
      "pyproject.toml", "setup.py", "setup.cfg", "Pipfile",
      "go.mod",
      "package.json", "tsconfig.json",
      "pom.xml", "build.gradle", "build.gradle.kts",
      "Gemfile", "build.zig", "cpanfile", "Makefile.PL",
      "docker-compose.yml", "docker-compose.yaml",
      ".editorconfig",
    })
    local dir
    if root and filepath:find(root, 1, true) == 1 then
      dir = root
    else
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

-- Prevent closing the last real file from terminating nvim.
-- :q on a file → replaces with scratch buffer, nvim stays alive.
-- :q on scratch/empty or dashboard → lets nvim exit normally.
-- :qa, :qall, :wqa, <leader>qq → always exit (they close all windows at once).
autocmd("QuitPre", {
  group = augroup("quit_guardian", { clear = true }),
  callback = function()
    -- Dashboard: user chose quit — let it through
    if vim.bo.filetype == "alpha" then return end
    -- Terminal buffers: don't intercept terminal close
    if vim.bo.buftype == "terminal" then return end
    -- Scratch/empty unnamed buffer: nothing to protect, let nvim exit
    local buf = vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_get_name(buf) == "" and vim.bo[buf].buftype == ""
        and not vim.bo[buf].modified then
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      if #lines <= 1 and (lines[1] or "") == "" then return end
    end
    -- This is a real file in the last (or only) real window — protect it.
    -- Replace with scratch so :q closes the file but nvim stays alive.
    if count_real_wins() <= 1 then
      vim.api.nvim_win_set_buf(0, get_scratch_buf())
      -- Close sidebars gracefully so the user lands on a clean scratch
      -- (they can reopen neo-tree etc. with keybindings)
    end
  end,
})

-- ══════════════════════════════════════════════════════════════════════════════
-- Diff Mode Layout Management + Claude Diff Cleanup
-- ══════════════════════════════════════════════════════════════════════════════
--
-- claudecode.nvim only sets b:claudecode_diff_tab_name on the PROPOSED buffer,
-- not the original file buffer. After claudecode deletes the proposed buffer,
-- that marker is gone. So we track diff participant buffers ourselves via
-- OptionSet and use that list for cleanup instead of relying on the marker.

local _neotree_was_open = false
local _in_claude_diff = false
local _diff_bufs = {}        -- {[buf_id] = true} buffers that entered diff mode during a Claude diff
local _cleanup_timer = nil   -- debounce timer to prevent event storms
local _saved_layout = nil    -- pruned winlayout snapshot used for full layout restore
local _snapshot_timer = nil  -- debounce timer for snapshotting the editor layout

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

local function is_empty_unnamed_buf(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return false end
  if vim.api.nvim_buf_get_name(buf) ~= "" then return false end
  if vim.bo[buf].buftype ~= "" then return false end
  if vim.bo[buf].modified then return false end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  return #lines <= 1 and (lines[1] or "") == ""
end

local function is_claude_terminal(buf)
  return vim.api.nvim_buf_is_valid(buf)
      and vim.bo[buf].buftype == "terminal"
      and vim.api.nvim_buf_get_name(buf):lower():match("claude") ~= nil
end

local function focus_claude_terminal()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) and is_claude_terminal(vim.api.nvim_win_get_buf(win)) then
      pcall(vim.api.nvim_set_current_win, win)
      -- Enter terminal mode directly (belt-and-suspenders with WinEnter autocmd).
      -- Schedule so the window switch fully settles before startinsert.
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win)
            and vim.api.nvim_get_current_win() == win
            and is_claude_terminal(vim.api.nvim_win_get_buf(win)) then
          vim.cmd.startinsert()
        end
      end)
      return true
    end
  end
  return false
end

-- ──────────────────────────────────────────────────────────────────────────
-- Layout snapshot/replay
--
-- We snapshot the editor's window layout (the pruned winlayout() tree, with
-- sidebars/terminals/floats removed) on every layout-changing event, debounced
-- so claudecode's transient mid-diff state never gets captured. The snapshot
-- is then replayed on diff exit to fully restore window structure, sizes,
-- buffers, and cursor positions.
--
-- Snapshots are skipped while a diff is active, so the snapshot in memory is
-- always the user's most recent clean editor state.
-- ──────────────────────────────────────────────────────────────────────────

local function capture_pruned_layout(node)
  if not node then return nil end
  local kind = node[1]
  if kind == "leaf" then
    local win = node[2]
    if not vim.api.nvim_win_is_valid(win) then return nil end
    if is_sidebar_win(win) then return nil end  -- prunes terminals/floats/neo-tree/etc
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == "terminal" then return nil end
    local cursor_ok, cursor = pcall(vim.api.nvim_win_get_cursor, win)
    return {
      kind = "leaf",
      buf = buf,
      cursor = cursor_ok and cursor or { 1, 0 },
      width = vim.api.nvim_win_get_width(win),
      height = vim.api.nvim_win_get_height(win),
    }
  elseif kind == "row" or kind == "col" then
    local children = {}
    for _, child in ipairs(node[2]) do
      local c = capture_pruned_layout(child)
      if c then table.insert(children, c) end
    end
    if #children == 0 then return nil end
    if #children == 1 then return children[1] end
    return { kind = kind, children = children }
  end
  return nil
end

-- Walk a saved tree, recreating splits from a single host window. Returns a
-- flat list of { node = leaf, win = win_id } pairs in tree order so the caller
-- can apply buffers/cursors/sizes in a second pass.
local function replay_layout(node, host_win)
  local pairs_list = {}
  local function recurse(n, win)
    if n.kind == "leaf" then
      table.insert(pairs_list, { node = n, win = win })
      return
    end
    local children = n.children
    if not children or #children == 0 then return end
    pcall(vim.api.nvim_set_current_win, win)
    local sibling_wins = { win }
    for i = 2, #children do
      local cmd = (n.kind == "row") and "rightbelow vsplit" or "rightbelow split"
      local ok = pcall(vim.cmd, cmd)
      if not ok then break end
      table.insert(sibling_wins, vim.api.nvim_get_current_win())
    end
    for i, child in ipairs(children) do
      if sibling_wins[i] then
        recurse(child, sibling_wins[i])
      end
    end
  end
  recurse(node, host_win)
  return pairs_list
end

local function snapshot_editor_layout()
  _snapshot_timer = nil
  if _in_claude_diff then return end
  -- Skip if any window is in diff mode (gitsigns diffthis, fugitive, etc.)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) and vim.wo[win].diff then return end
  end
  local tree = capture_pruned_layout(vim.fn.winlayout())
  if tree then
    _saved_layout = tree
  end
end

local function schedule_snapshot()
  if _in_claude_diff then return end
  if _snapshot_timer then
    pcall(function() _snapshot_timer:stop() end)
  end
  -- 250ms debounce: long enough that claudecode's burst of WinNew/BufWinEnter
  -- between create_split → :edit → diffthis all collapses into a single check
  -- which then bails because the diff is up.
  _snapshot_timer = vim.defer_fn(snapshot_editor_layout, 250)
end

local function diff_cleanup()
  _cleanup_timer = nil
  if not _in_claude_diff then return end
  -- Still in an active diff — don't clean up yet
  if any_diff_windows() then return end

  _in_claude_diff = false
  local participant_bufs = _diff_bufs
  _diff_bufs = {}
  local saved_layout = _saved_layout
  _saved_layout = nil

  -- 1. Force diffoff on any lingering windows
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) and vim.wo[win].diff then
      vim.api.nvim_win_call(win, function() vim.cmd("diffoff") end)
    end
  end

  -- 2. Close any non-sidebar editor window holding a diff participant or
  -- claude pseudo-buffer. This collapses claudecode's leftover diff windows
  -- so we can replay the saved layout from a single host window.
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) and not is_sidebar_win(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].buftype ~= "terminal"
          and (participant_bufs[buf] or is_claude_diff_buf(buf)) then
        if #vim.api.nvim_tabpage_list_wins(0) > 1 then
          pcall(vim.api.nvim_win_close, win, true)
        end
      end
    end
  end

  -- 3. Make sure at least one editor window survives to host the replay.
  ensure_editor_window()

  -- 4. Pick a host window and close any other surviving editor windows.
  -- Replay needs to start from exactly one window so split commands attach
  -- to the right place.
  local host_win = nil
  local extras = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) and not is_sidebar_win(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].buftype ~= "terminal" then
        if not host_win then
          host_win = win
        else
          table.insert(extras, win)
        end
      end
    end
  end
  for _, win in ipairs(extras) do
    if vim.api.nvim_win_is_valid(win) and #vim.api.nvim_tabpage_list_wins(0) > 1 then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end

  -- 5. Replay the saved winlayout from the host. Each leaf in the saved tree
  -- becomes a new sibling window via row/col splits, with the original buffer
  -- and cursor restored. Sizes are applied in a final pass.
  if host_win and vim.api.nvim_win_is_valid(host_win) and saved_layout then
    local pairs_list = replay_layout(saved_layout, host_win)

    for _, p in ipairs(pairs_list) do
      local win, node = p.win, p.node
      if vim.api.nvim_win_is_valid(win) and node.kind == "leaf" then
        if node.buf and vim.api.nvim_buf_is_valid(node.buf)
            and vim.api.nvim_buf_is_loaded(node.buf) then
          pcall(vim.api.nvim_win_set_buf, win, node.buf)
          if node.cursor then
            pcall(vim.api.nvim_win_set_cursor, win, node.cursor)
          end
        else
          -- Saved buffer is gone — fall back to scratch
          pcall(vim.api.nvim_win_set_buf, win, get_scratch_buf())
        end
      end
    end

    -- Apply saved widths/heights after all buffers are placed so cursor and
    -- statusline state don't trip up sizing math.
    for _, p in ipairs(pairs_list) do
      if vim.api.nvim_win_is_valid(p.win) then
        if p.node.width then
          pcall(vim.api.nvim_win_set_width, p.win, p.node.width)
        end
        if p.node.height then
          pcall(vim.api.nvim_win_set_height, p.win, p.node.height)
        end
      end
    end
  end

  -- 6. Delete claude pseudo-buffers (the proposed-side ones with the marker)
  -- that are no longer displayed. Real file participant buffers are kept in
  -- the buffer list — the user might still want them.
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf)
        and is_claude_diff_buf(buf) then
      local displayed = false
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
          displayed = true
          break
        end
      end
      if not displayed then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
  end

  -- 7. Restore neo-tree if it was open before the diff
  if _neotree_was_open then
    _neotree_was_open = false
    pcall(vim.cmd, "Neotree show left")
  end

  -- 8. Return focus to Claude terminal
  focus_claude_terminal()
end

local function schedule_diff_cleanup()
  if not _in_claude_diff then return end
  -- Debounce: cancel any pending timer and set a new one.
  -- 150ms delay lets claudecode finish its own synchronous cleanup first.
  if _cleanup_timer then
    pcall(function() _cleanup_timer:stop() end)
  end
  _cleanup_timer = vim.defer_fn(function()
    diff_cleanup()
  end, 150)
end

-- Entering diff mode: track Claude diff participants, hide neo-tree
--
-- CRITICAL TIMING: claudecode.nvim calls diffthis BEFORE setting the
-- b:claudecode_diff_tab_name marker (setup_new_buffer lines 578/588 vs 594).
-- Both OptionSet events fire before the marker exists. A synchronous check
-- would ALWAYS fail. We MUST defer via vim.schedule so the check runs after
-- claudecode finishes setup_new_buffer and the marker is in place.
autocmd("OptionSet", {
  group = augroup("diff_layout", { clear = true }),
  pattern = "diff",
  callback = function()
    local new_val = vim.v.option_new
    if new_val == false or new_val == "0" or new_val == 0 then return end

    vim.schedule(function()
      -- Scan all windows currently in diff mode for Claude markers
      local claude_diff_found = false
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_is_valid(win) and vim.wo[win].diff then
          if is_claude_diff_buf(vim.api.nvim_win_get_buf(win)) then
            claude_diff_found = true
            break
          end
        end
      end

      -- Not a Claude diff (e.g. gitsigns diffthis) — ignore
      if not claude_diff_found then return end

      -- Track ALL buffers currently in diff mode (original + proposed)
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_is_valid(win) and vim.wo[win].diff then
          _diff_bufs[vim.api.nvim_win_get_buf(win)] = true
        end
      end

      if not _in_claude_diff then
        _in_claude_diff = true
        -- If a debounced snapshot is still pending, drop it — the most recent
        -- pre-diff snapshot in _saved_layout is the one we want to replay.
        if _snapshot_timer then
          pcall(function() _snapshot_timer:stop() end)
          _snapshot_timer = nil
        end
        -- Defensive fallback: if no snapshot was ever taken (e.g. user opened
        -- a diff before any layout-change event fired), capture the current
        -- non-diff windows now. Better than no restoration at all.
        if not _saved_layout then
          _saved_layout = capture_pruned_layout(vim.fn.winlayout())
        end
        if neotree_is_visible() then
          _neotree_was_open = true
          pcall(vim.cmd, "Neotree close")
        end
        -- Hide every non-diff editor window so the diffs get the entire
        -- editor area to themselves. The full layout is preserved in
        -- _saved_layout for replay on diff exit. We can close unconditionally
        -- here: the diff windows are guaranteed to exist (we just detected
        -- one above), so the tab can never become empty.
        local wins_to_close = {}
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          if vim.api.nvim_win_is_valid(win) and not is_sidebar_win(win) and not vim.wo[win].diff then
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].buftype ~= "terminal" and not _diff_bufs[buf] then
              table.insert(wins_to_close, win)
            end
          end
        end
        for _, win in ipairs(wins_to_close) do
          if vim.api.nvim_win_is_valid(win) then
            pcall(vim.api.nvim_win_close, win, false)
          end
        end
        -- Re-equalize remaining diff windows now that the extras are gone
        pcall(vim.cmd, "wincmd =")
        -- Shift focus back to Claude terminal so user can keep typing to Claude
        -- while the diff is visible. Delay lets claudecode finish its own focus
        -- setup before we override it.
        vim.defer_fn(focus_claude_terminal, 150)
      end
    end)
  end,
})

-- Exiting diff mode: clean up when diff windows close
autocmd("WinClosed", {
  group = augroup("diff_cleanup_winclosed", { clear = true }),
  callback = function()
    if not _in_claude_diff then return end
    schedule_diff_cleanup()
  end,
})

-- Safety net: catch async plugin cleanup that doesn't fire WinClosed
autocmd("BufEnter", {
  group = augroup("diff_cleanup_bufenter", { clear = true }),
  callback = function()
    if not _in_claude_diff then return end
    if vim.bo.buftype == "terminal" then return end
    schedule_diff_cleanup()
  end,
})

-- Snapshot the editor's window layout on every layout-changing event so we
-- have a fresh tree to replay on diff exit. The snapshot is debounced (250ms)
-- and skips while a diff is active, so claudecode's mid-diff churn never
-- pollutes the captured state.
autocmd({ "WinNew", "WinClosed", "BufWinEnter" }, {
  group = augroup("editor_layout_snapshot", { clear = true }),
  callback = schedule_snapshot,
})

-- ══════════════════════════════════════════════════════════════════════════════
-- Claude Terminal Auto-Scroll: enter terminal mode when Claude terminal gains
-- focus so the view anchors to the prompt. Switching away exits terminal mode
-- (normal nvim behavior); switching back re-enters it. Users can still scroll
-- back with <C-\><C-n> without leaving the window — WinEnter won't re-fire.
-- ══════════════════════════════════════════════════════════════════════════════

autocmd("WinEnter", {
  group = augroup("claude_terminal_scroll", { clear = true }),
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    if not is_claude_terminal(buf) then return end
    -- Schedule so layout operations (split, set_buf, resize) fully settle first.
    -- startinsert on a terminal buffer enters Terminal-Job mode (the "insert
    -- mode" for terminals), which anchors the viewport to the terminal cursor.
    vim.schedule(function()
      if is_claude_terminal(vim.api.nvim_get_current_buf())
          and vim.api.nvim_get_mode().mode ~= "t" then
        vim.cmd.startinsert()
      end
    end)
  end,
})
