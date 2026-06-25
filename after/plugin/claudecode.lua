local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "claudecode") then
  -- Default configuration
  local default_config = {
    terminal_cmd = "claude",
    auto_close = true,
    track_selection = true,
    auto_start = true,
    log_level = "warn",
    diff_opts = {
      auto_close_on_accept = true,
      layout = "vertical",
      open_in_new_tab = true,
      hide_terminal_in_new_tab = false,
    },
    terminal = {
      show_native_term_exit_tip = false,
      split_side = "right",
      split_width_percentage = 0.40,
      -- Focusing the terminal scrolls to the prompt and enters insert mode
      -- (plugin default, set explicitly so the behavior is guaranteed).
      auto_insert = true,
    },
  }

  -- Current position (can be changed at runtime)
  _G.claudecode_position = _G.claudecode_position or "right"

  -- Position configs for snacks_win_opts (bypasses plugin validation for top/bottom)
  local position_configs = {
    left = { position = "left", width = 0.40, height = 0 },
    right = { position = "right", width = 0.40, height = 0 },
    top = { position = "top", height = 0.35, width = 0 },
    bottom = { position = "bottom", height = 0.35, width = 0 },
  }

  -- Build terminal config for a given position
  local function terminal_config_for(position)
    local pos_config = position_configs[position]
    return {
      split_side = (position == "left" or position == "right") and position or "right",
      split_width_percentage = pos_config.width > 0 and pos_config.width or 0.40,
      snacks_win_opts = pos_config,
    }
  end

  -- Initial setup (only called once — avoids server restart)
  local initial_terminal = terminal_config_for(_G.claudecode_position)
  require("claudecode").setup(vim.tbl_deep_extend("force", default_config, {
    terminal = initial_terminal,
  }))

  -- Absolute split commands (layout-independent positioning)
  local split_for = {
    left = "topleft vsplit",
    right = "botright vsplit",
    top = "topleft split",
    bottom = "botright split",
  }

  -- Terminal buffer we've taken over management of (after a position switch)
  local managed_buf = nil

  -- Find the claude terminal buffer.
  -- Prefer the plugin's official API (resolves both Snacks and native providers
  -- and is immune to buffer-naming changes); fall back to a name scan only if
  -- the API is unavailable or returns nothing.
  local function find_claude_term_buf()
    local ok, term = pcall(require, "claudecode.terminal")
    if ok and type(term.get_active_terminal_bufnr) == "function" then
      local buf = term.get_active_terminal_bufnr()
      if buf and vim.api.nvim_buf_is_valid(buf) then
        return buf
      end
    end
    -- Fallback: scan for a terminal buffer named after the claude command.
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
        local name = vim.api.nvim_buf_get_name(buf)
        if name:match("claude") then
          return buf
        end
      end
    end
    return nil
  end

  -- Find the window displaying a buffer (nil if hidden)
  local function find_buf_win(buf)
    if not buf or not vim.api.nvim_buf_is_valid(buf) then
      return nil
    end
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == buf then
        return win
      end
    end
    return nil
  end

  -- Sidebars/utility panes that a top/bottom Claude split must NOT span across,
  -- so the terminal stops at the neo-tree boundary and the IDE layout is kept.
  -- Mirrors sidebar_filetypes in config/autocommands.lua.
  local sidebar_fts = {
    ["neo-tree"] = true,
    ["Trouble"] = true,
    ["qf"] = true,
    ["help"] = true,
    ["snacks_terminal"] = true,
    ["dapui_scopes"] = true,
    ["dapui_breakpoints"] = true,
    ["dapui_stacks"] = true,
    ["dapui_watches"] = true,
    ["dapui_console"] = true,
    ["dap-repl"] = true,
  }

  -- A "real" editor window: not floating, not a terminal, not a sidebar pane.
  local function is_editor_win(win)
    if not vim.api.nvim_win_is_valid(win) then
      return false
    end
    local cfg = vim.api.nvim_win_get_config(win)
    if cfg.relative and cfg.relative ~= "" then
      return false
    end
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == "terminal" then
      return false
    end
    return not sidebar_fts[vim.bo[buf].filetype]
  end

  -- Find an editor window to anchor a confined split to (prefer current).
  local function find_editor_win()
    local cur = vim.api.nvim_get_current_win()
    if is_editor_win(cur) then
      return cur
    end
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if is_editor_win(win) then
        return win
      end
    end
    return nil
  end

  -- Check if we're managing the terminal ourselves
  local function is_managed()
    if managed_buf and vim.api.nvim_buf_is_valid(managed_buf) then
      return true
    end
    managed_buf = nil
    return false
  end

  -- Scroll the Claude terminal to the prompt and enter Terminal-Job mode (the
  -- "insert mode" for terminal buffers) so the user can type immediately. Once
  -- our layer takes over a terminal's window it is no longer Snacks-managed, so
  -- Snacks' own start_insert/scroll handling no longer applies -- we do it here.
  -- The WinEnter `claude_terminal_scroll` autocmd reinforces this on every focus.
  local function enter_terminal_mode()
    vim.schedule(function()
      local win = vim.api.nvim_get_current_win()
      local buf = vim.api.nvim_get_current_buf()
      if vim.bo[buf].buftype ~= "terminal" then
        return
      end
      pcall(vim.api.nvim_win_set_cursor, win, { vim.api.nvim_buf_line_count(buf), 0 })
      if vim.api.nvim_get_mode().mode ~= "t" then
        vim.cmd.startinsert()
      end
    end)
  end

  -- Resize a window for the current position
  local function resize_for_position(win)
    local pos_config = position_configs[_G.claudecode_position]
    if _G.claudecode_position == "left" or _G.claudecode_position == "right" then
      local width = math.floor(vim.o.columns * (pos_config.width > 0 and pos_config.width or 0.40))
      vim.api.nvim_win_set_width(win, width)
    else
      local height = math.floor(vim.o.lines * (pos_config.height > 0 and pos_config.height or 0.35))
      vim.api.nvim_win_set_height(win, height)
    end
  end

  -- Show the managed terminal in the current position.
  -- left/right: full-height vertical split at the screen edge.
  -- top/bottom: horizontal split confined to the editor area so it stops at the
  -- neo-tree/sidebar boundary (IDE-like layout) instead of spanning full width.
  local function show_managed()
    if not (managed_buf and vim.api.nvim_buf_is_valid(managed_buf)) then
      return
    end
    local pos = _G.claudecode_position
    if pos == "top" or pos == "bottom" then
      local target = find_editor_win()
      if target then
        -- aboveleft/belowright split the *current* window only, so the new
        -- terminal inherits the editor window's width (= editor area, right of
        -- the sidebar) rather than the full screen width that topleft/botright
        -- would force.
        vim.api.nvim_set_current_win(target)
        vim.cmd(pos == "top" and "aboveleft split" or "belowright split")
      else
        -- Sidebar-only layout (no editor window): fall back to full width.
        vim.cmd(split_for[pos])
      end
    else
      vim.cmd(split_for[pos])
    end
    vim.api.nvim_win_set_buf(0, managed_buf)
    resize_for_position(0)
    enter_terminal_mode()
  end

  -- Toggle the managed terminal (show/hide)
  local function managed_toggle()
    local win = find_buf_win(managed_buf)
    if win then
      -- Visible → hide (just close window, keep buffer/process)
      vim.api.nvim_win_close(win, false)
    else
      -- Hidden → show in current position
      show_managed()
    end
  end

  -- Switch terminal position at runtime by moving the existing window
  local function switch_position(position)
    local pos_config = position_configs[position]
    if not pos_config then
      return
    end
    _G.claudecode_position = position

    -- Update terminal defaults for future terminals
    local term = require("claudecode.terminal")
    local tc = terminal_config_for(position)
    term.defaults.split_side = tc.split_side
    term.defaults.split_width_percentage = tc.split_width_percentage
    term.defaults.snacks_win_opts = tc.snacks_win_opts

    -- Capture the user's window up front so warm repositioning can return to it.
    local prev_win = vim.api.nvim_get_current_win()

    -- Take over a terminal buffer and (re)show it confined to the current
    -- position. restore_focus returns the cursor to prev_win afterwards.
    local function take_over_and_show(term_buf, restore_focus)
      managed_buf = term_buf
      local term_win = find_buf_win(term_buf)
      if term_win then
        vim.api.nvim_win_close(term_win, false)
      end
      show_managed()
      if restore_focus and vim.api.nvim_win_is_valid(prev_win) then
        vim.api.nvim_set_current_win(prev_win)
      end
    end

    -- Find the terminal buffer (check managed first, then search)
    local term_buf = is_managed() and managed_buf or find_claude_term_buf()
    if term_buf then
      -- Existing terminal: move it, keeping the user where they were.
      take_over_and_show(term_buf, true)
      return
    end

    -- No terminal yet: let the plugin create it, then immediately take over so
    -- the confined top/bottom layout is applied. snacks would otherwise place a
    -- full-width split that overruns the sidebar. Focus lands in the new Claude
    -- terminal (natural for a first open), not back in the sidebar.
    vim.cmd("ClaudeCode")
    vim.schedule(function()
      local buf = find_claude_term_buf()
      if buf then
        take_over_and_show(buf, false)
      end
    end)
  end

  -- Override ClaudeCode toggle to handle managed terminals
  vim.api.nvim_create_user_command("ClaudeCode", function(opts)
    if is_managed() then
      managed_toggle()
    else
      -- Default plugin behavior
      local cmd_args = opts.args ~= "" and opts.args or nil
      require("claudecode.terminal").simple_toggle({}, cmd_args)
    end
  end, { nargs = "*", force = true, desc = "Toggle Claude Code terminal" })

  -- Override ClaudeCodeClose to handle managed terminals
  vim.api.nvim_create_user_command("ClaudeCodeClose", function()
    if is_managed() then
      local win = find_buf_win(managed_buf)
      if win then
        vim.api.nvim_win_close(win, false)
      end
    else
      require("claudecode.terminal").close()
    end
  end, { force = true, desc = "Close Claude Code terminal" })

  -- Override ClaudeCodeFocus to handle managed terminals
  vim.api.nvim_create_user_command("ClaudeCodeFocus", function()
    if is_managed() then
      local win = find_buf_win(managed_buf)
      if win then
        if vim.api.nvim_get_current_win() == win then
          vim.api.nvim_win_close(win, false)
        else
          vim.api.nvim_set_current_win(win)
          enter_terminal_mode()
        end
      else
        show_managed()
      end
    else
      require("claudecode.terminal").focus_toggle({})
      -- Plugin's focus_toggle opens/focuses the terminal; scroll to bottom
      enter_terminal_mode()
    end
  end, { force = true, desc = "Focus/toggle Claude Code terminal" })

  -- Create commands for position switching
  local positions = { "left", "right", "top", "bottom" }
  for _, pos in ipairs(positions) do
    vim.api.nvim_create_user_command("ClaudeCode" .. pos:gsub("^%l", string.upper), function()
      switch_position(pos)
    end, { desc = "Open Claude Code on " .. pos })
  end

  -- Expose for keybindings
  _G.claudecode_set_position = switch_position

  -- New-tab diff: claudecode always opens its terminal as a left/right split in
  -- the new tab. Reposition it to match _G.claudecode_position (so top/bottom
  -- preferences are honored) and resize it. Triggered by TabNew + a deferred
  -- check for a Claude diff buffer in the new tab.
  vim.api.nvim_create_autocmd("TabNew", {
    group = vim.api.nvim_create_augroup("LushClaudeDiffTab", { clear = true }),
    callback = function()
      vim.defer_fn(function()
        local tab = vim.api.nvim_get_current_tabpage()
        if not vim.api.nvim_tabpage_is_valid(tab) then
          return
        end

        -- Confirm this tab is hosting a Claude diff (buffer name suffix or marker)
        local claude_term_buf = find_claude_term_buf()
        local has_claude_diff = false
        local term_win = nil
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
          local buf = vim.api.nvim_win_get_buf(win)
          if vim.bo[buf].buftype == "terminal" and buf == claude_term_buf then
            term_win = win
          end
          local name = vim.api.nvim_buf_get_name(buf)
          if name:match("%s%(New%)$") then
            has_claude_diff = true
          end
          local ok, val = pcall(vim.api.nvim_buf_get_var, buf, "claudecode_diff_tab_name")
          if ok and val ~= nil then
            has_claude_diff = true
          end
        end
        if not has_claude_diff or not term_win then
          return
        end

        -- Reuse same split commands and width math as the original-tab logic
        local term_buf = vim.api.nvim_win_get_buf(term_win)
        vim.api.nvim_win_close(term_win, false)
        vim.cmd(split_for[_G.claudecode_position])
        vim.api.nvim_win_set_buf(0, term_buf)
        resize_for_position(0)
        -- Return focus to the diff so the user can review immediately
        vim.cmd("wincmd p")
      end, 60)
    end,
  })
end
