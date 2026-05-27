local M = {}

-- OS detection helpers
M.is_mac = vim.fn.has("macunix") == 1
M.is_linux = vim.fn.has("unix") == 1 and not M.is_mac
M.is_windows = vim.fn.has("win32") == 1

-- Option registry — sister of the keymap registry. Tracks every option
-- LushNvim sets so :LushReload can reset them to defaults before re-applying.
-- Without this, an option you remove from user.config or M.options would
-- linger until restart (vim has no "diff from defaults" API).
_G.lush_tracked_opts = _G.lush_tracked_opts or {}

-- sets main options from options (table), recording each (scope, setting) pair
-- in the registry so :LushReload can reset removed entries.
M.vim_opts = function(options)
  if options == nil then
    return
  end
  for scope, table in pairs(options) do
    for setting, value in pairs(table) do
      vim[scope][setting] = value
      -- Only track scopes that are user-facing (skip wo/bo which are
      -- window/buffer-local and managed by their own lifecycle).
      if scope == "o" or scope == "opt" or scope == "go" or scope == "g" then
        _G.lush_tracked_opts[scope .. ":" .. setting] = true
      end
    end
  end
end

-- Reset every tracked option to its default. Called by :LushReload before
-- re-sourcing so removed entries from user.config actually disappear.
M.clear_tracked_opts = function()
  for key in pairs(_G.lush_tracked_opts) do
    local scope, setting = key:match("^([^:]+):(.+)$")
    if scope == "g" then
      -- Variables: just unset
      pcall(function()
        vim.g[setting] = nil
      end)
    elseif scope and setting then
      -- Options: `:set name&` restores the built-in default.
      pcall(vim.cmd, "set " .. setting .. "&")
    end
  end
  _G.lush_tracked_opts = {}
end

-- check if inside a working git repository
M.is_git_repo = function()
  local _ = vim.fn.system("git rev-parse --is-inside-work-tree")
  return vim.v.shell_error == 0
end

-- creating new file for alpha nvim buffer
M.create_new_file = function()
  local filename = vim.fn.input("Enter the filename: ")
  if filename ~= "" then
    vim.cmd.edit(filename)
  end
end

-- helper for cmp completion
M.has_words_before = function()
  local line, col = table.unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0
    and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

-- Floating tool-terminal helper removed May 2026: replaced by snacks.terminal.
-- See after/plugin/terminal.lua for the gdu/btop wrappers that now use
-- Snacks.terminal.toggle(cmd, { win = { position = "float", ... } }).

-- updates all Mason packages
M.update_mason = function()
  local registry = require("mason-registry")
  registry.refresh()
  registry.update()
  local packages = registry.get_all_packages()
  for _, pkg in ipairs(packages) do
    if pkg:is_installed() then
      pkg:install()
    end
  end
end

-- updates everything in LushNvim
M.update_all = function()
  M.notify_info("Pulling latest changes...")
  vim.fn.system({ "git", "pull", "--rebase" })
  -- lazy.sync handles plugin updates + treesitter parser recompilation via build = ":TSUpdate"
  require("lazy").sync({ wait = true })
  M.notify_info("Updating Mason packages...")
  M.update_mason()
  M.notify_info("LushNvim updated!")
end

-- get attached lsp servers
M.get_attached_clients = function()
  -- Returns a string with a list of attached LSP clients, including
  -- formatters and linters from null-ls, nvim-lint and formatter.nvim
  local buf_clients = vim.lsp.get_clients({ bufnr = 0 })
  if #buf_clients == 0 then
    return "LSP Inactive"
  end

  local buf_ft = vim.bo.filetype
  local buf_client_names = {}

  -- add client
  for _, client in pairs(buf_clients) do
    if client.name ~= "copilot" and client.name ~= "null-ls" then
      table.insert(buf_client_names, client.name)
    end
  end

  -- Add sources (from null-ls/none-ls)
  local null_ls_s, null_ls = pcall(require, "null-ls")
  if null_ls_s then
    local sources = null_ls.get_sources()
    for _, source in ipairs(sources) do
      if source._validated then
        for ft_name, ft_active in pairs(source.filetypes) do
          if ft_name == buf_ft and ft_active then
            table.insert(buf_client_names, source.name)
          end
        end
      end
    end
  end

  -- Deduplicate client names (O(n) using set)
  local seen = {}
  local unique_client_names = {}
  for _, name in ipairs(buf_client_names) do
    if not seen[name] then
      table.insert(unique_client_names, name)
      seen[name] = true
    end
  end

  local client_names_str = table.concat(unique_client_names, ", ")
  local language_servers = string.format("[%s]", client_names_str)

  return language_servers
end

-- check if attached lsp supports formatting
M.supports_formatting = function()
  local clients = vim.lsp.get_clients()
  for _, client in ipairs(clients) do
    if client.supports_method("textDocument/formatting") then
      return true
    end
  end
  return false
end

-- check if option to disable is active from specified group
M.enabled = function(group, opt)
  return group == nil or group[opt] == nil or group[opt] == true
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Keymap registry — so :LushReload can clear keymaps set by features that are
-- now disabled in user.config. The registry lives on _G so it survives
-- package.loaded clearing during reload.
-- ──────────────────────────────────────────────────────────────────────────────
_G.lush_tracked_keymaps = _G.lush_tracked_keymaps or {}

-- Drop-in replacement for vim.keymap.set that records every (mode, lhs) pair
-- in the registry. Buffer-local mappings are skipped (they die with the buf).
M.map = function(mode, lhs, rhs, opts)
  opts = opts or {}
  if not opts.buffer then
    local modes = type(mode) == "table" and mode or { mode }
    for _, m in ipairs(modes) do
      table.insert(_G.lush_tracked_keymaps, { mode = m, lhs = lhs })
    end
  end
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- For plugins (snacks.toggle, etc.) that bind keymaps via their own API.
-- Call this immediately after to make the binding reload-aware.
M.track_keymap = function(mode, lhs)
  local modes = type(mode) == "table" and mode or { mode }
  for _, m in ipairs(modes) do
    table.insert(_G.lush_tracked_keymaps, { mode = m, lhs = lhs })
  end
end

-- Remove every tracked keymap from vim and reset the registry. Called by
-- :LushReload before re-sourcing so disabled features don't leave stale binds.
M.clear_tracked_keymaps = function()
  for _, km in ipairs(_G.lush_tracked_keymaps) do
    pcall(vim.keymap.del, km.mode, km.lhs)
  end
  _G.lush_tracked_keymaps = {}
end

-- get user config value (reduces boilerplate in plugin files)
M.get_user_config = function(key)
  local exist, user_config = pcall(require, "user.config")
  if exist and type(user_config) == "table" then
    return key and user_config[key] or user_config
  end
  return {}
end

-- get enable_plugins group from user config
M.get_plugin_group = function()
  return M.get_user_config("enable_plugins")
end

M.notify_info = function(body, header)
  message.notify(body, "info", { title = header })
end

M.notify_warn = function(body, header)
  message.notify(body, "warn", { title = header })
end

M.notify_error = function(body, header)
  message.notify(body, "error", { title = header })
end

M.colors = function(scheme)
  vim.cmd.colorscheme(scheme)
end

-- Swap every window showing `bufnr` to a sibling listed buffer first, then
-- delete. Doing it in this order keeps the editor window alive: vim's own
-- bdelete-on-active-buffer path closes the window in our IDE layout (1 editor
-- + neo-tree sidebar), which trips the layout guardian and equalizes the
-- splits. Pre-swapping avoids that path entirely.
M.safe_close_buffer = function(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local function pick_alt()
    local alt = vim.fn.bufnr("#")
    if
      alt > 0
      and alt ~= bufnr
      and vim.api.nvim_buf_is_valid(alt)
      and vim.bo[alt].buflisted
      and vim.bo[alt].buftype == ""
    then
      return alt
    end
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if
        b ~= bufnr
        and vim.api.nvim_buf_is_valid(b)
        and vim.api.nvim_buf_is_loaded(b)
        and vim.bo[b].buflisted
        and vim.bo[b].buftype == ""
      then
        return b
      end
    end
    return nil
  end

  local alt = pick_alt()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == bufnr and alt then
      vim.api.nvim_win_set_buf(win, alt)
    end
  end

  pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
end

-- Statusline style selector. Stores the choice and applies it eagerly so the
-- order of after/plugin/lualine.lua vs custom_conf() doesn't matter — mirrors
-- how M.colors applies the colorscheme directly. If lualine isn't loaded yet,
-- styles.apply silently no-ops and after/plugin/lualine.lua picks it up later.
-- Runtime override via :LushStatusline.
local _statusline_choice = nil
M.statusline = function(name)
  _statusline_choice = name
  local ok, styles = pcall(require, "lush.statuslines")
  if ok and type(styles.apply) == "function" then
    pcall(styles.apply, name)
  end
end
M.get_statusline = function()
  return _statusline_choice
end

return M
