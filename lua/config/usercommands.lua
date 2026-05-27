local create_user_command = vim.api.nvim_create_user_command

create_user_command("LushUpdate", function()
  require("config.utils").update_all()
end, { desc = "Updates plugins, mason packages, treesitter parsers" })

-- Hot-reload LushNvim's own modules and re-source after/plugin/*. `:LushReload!`
-- (bang) additionally replays `user.config.custom_conf()` — useful when you've
-- edited the colorscheme / statusline choice in user/config.lua and want the
-- same effect as a fresh start (including the startup greeting).
--
-- What this handles:
--   - Options, autocmds (augroup clear=true), user commands, LSP config regs,
--     and all after/plugin setup functions.
--   - Keymaps set via utils.map / utils.track_keymap are cleared first and
--     re-bound by the re-source, so disabling a plugin in user.config and
--     reloading removes its bindings (instead of leaving them stale in
--     which-key).
--   - LSP clients are auto-restarted at the end so updated lsp_configs land
--     on already-attached buffers.
--
-- What it can NOT do (Neovim limitations):
--   - Lazy plugins that configure inline via `config = function` in lazy.lua
--     never re-run that block (lazy fires it once). Move config to
--     after/plugin/<plugin>.lua for reload awareness.
--   - Plugin-internal keymaps (set inside a plugin's own setup) only re-bind
--     when their setup is called again — handled via the after/plugin
--     re-source pass for our own configs, but plugins that don't expose a
--     setup or whose setup is one-shot retain their old internal state.
--   - Options that LushNvim previously set in M.options but later removed
--     stay applied until restart (vim has no "diff from defaults" API).
create_user_command("LushReload", function(opts)
  local utils = require("config.utils")
  local cleared = 0
  local failed = {}

  -- 0. Capture the active statusline so we can restore it after module clear.
  --    Without this, non-bang :LushReload re-sources after/plugin/lualine.lua
  --    against a fresh config.utils whose _statusline_choice is nil, dropping
  --    the runtime choice back to the default.
  local saved_statusline
  local ok_styles, styles_mod = pcall(require, "lush.statuslines")
  if ok_styles and type(styles_mod.current) == "function" then
    saved_statusline = styles_mod.current()
  end

  -- 0b. Clear every keymap LushNvim registered. After re-source, only the
  --     keymaps gated by currently-enabled features will be re-bound, so
  --     toggling `enable_plugins.foo = false` and reloading actually removes
  --     foo's mappings (instead of leaving stale binds in which-key).
  pcall(utils.clear_tracked_keymaps)

  -- 0c. Reset every option LushNvim set so removed entries from M.options
  --     in user.config actually disappear on reload (instead of lingering
  --     until restart). Options not listed will be re-applied by the
  --     re-source pass right after.
  pcall(utils.clear_tracked_opts)

  -- 1. Clear every LushNvim module so `require` re-executes them.
  --    Covers config.*, user.* (plugin-configs, usercommands, etc.) and
  --    the lush.* subtree (statuslines, health).
  local prefixes = { "^config%.", "^user%.", "^lush%." }
  for name, _ in pairs(package.loaded) do
    for _, pat in ipairs(prefixes) do
      if name:match(pat) then
        package.loaded[name] = nil
        cleared = cleared + 1
        break
      end
    end
  end

  -- 2. Re-require the core entry points in a deterministic order. user.config
  --    pulls in config.languages via its `apply()` call, so we don't need to
  --    require that one explicitly.
  local entrypoints = {
    "config.utils",
    "config.options",
    "config.keybindings",
    "config.autocommands",
    "config.lsp",
    "config.usercommands",
    "user.config",
  }
  for _, module in ipairs(entrypoints) do
    local ok, err = pcall(require, module)
    if not ok then
      table.insert(failed, module .. ": " .. tostring(err))
    end
  end

  -- 3. Re-apply user options (user.config sets them only inside custom_conf
  --    on first load; re-applying here keeps edits to M.options live without
  --    forcing custom_conf replay).
  local user_ok, user_config = pcall(require, "user.config")
  if user_ok and type(user_config) == "table" and user_config.options then
    utils.vim_opts(user_config.options)
  end

  -- 4a. Restore the statusline choice into the fresh config.utils module so
  --     after/plugin/lualine.lua reads the right value when it re-sources.
  if saved_statusline then
    local ok_utils, fresh_utils = pcall(require, "config.utils")
    if ok_utils and type(fresh_utils.statusline) == "function" then
      pcall(fresh_utils.statusline, saved_statusline)
    end
  end

  -- 4b. Re-source every after/plugin/*.lua so telescope/lualine/typescript/etc.
  --     pick up edits. All LushNvim after/plugin files use augroup clear=true
  --     and idempotent setup() calls, so re-sourcing is safe.
  local ok_rt, rt_err = pcall(vim.cmd, "runtime! after/plugin/*.lua")
  if not ok_rt then
    table.insert(failed, "after/plugin runtime: " .. tostring(rt_err))
  end

  -- 4c. Restart LSP clients so they pick up changes to lsp_configs in user.config.
  --     Already-attached clients hold their old config until restarted.
  pcall(vim.cmd, "LspRestart")

  -- 5. Bang variant: replay user_config.custom_conf() to re-set colorscheme,
  --    statusline choice, and re-require user.usercommands. Announces itself
  --    via the "Here be dragons" greeting — intentional, that's the signal
  --    that a full replay just happened.
  if
    opts.bang
    and user_ok
    and type(user_config) == "table"
    and type(user_config.custom_conf) == "function"
  then
    local ok, err = pcall(user_config.custom_conf)
    if not ok then
      table.insert(failed, "custom_conf: " .. tostring(err))
    end
  end

  -- 6. Polish: clear stale search highlights and dismiss any lingering
  --    notifications so the reload lands on a clean slate.
  pcall(vim.cmd, "nohlsearch")
  local ok_notify, notify = pcall(require, "notify")
  if ok_notify and type(notify.dismiss) == "function" then
    pcall(notify.dismiss, { silent = true, pending = true })
  end

  -- 7. Report.
  if #failed > 0 then
    utils.notify_error("Reload errors:\n" .. table.concat(failed, "\n"), "LushReload")
  else
    local msg = string.format("Cleared %d modules, re-sourced after/plugin", cleared)
    if opts.bang then
      msg = msg .. " (with custom_conf replay)"
    end
    utils.notify_info(msg, "LushReload")
  end
end, {
  bang = true,
  desc = "Hot-reload LushNvim config (bang: also replay custom_conf)",
})

-- Show current buffer tooling status in a floating window
create_user_command("LushInfo", function()
  local buf = vim.api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype
  local bufname = vim.api.nvim_buf_get_name(buf)

  local lines = {}
  local function add(text)
    table.insert(lines, text)
  end
  local function header(text)
    add("")
    add("--- " .. text .. " ---")
  end

  add("=== LushInfo ===")
  add("Buffer: " .. (bufname ~= "" and bufname or "[No Name]"))
  add("Filetype: " .. (ft ~= "" and ft or "(none)"))

  -- LSP clients
  header("LSP Clients")
  local clients = vim.lsp.get_clients({ bufnr = buf })
  local has_clients = false
  for _, client in ipairs(clients) do
    if client.name ~= "copilot" then
      local root = client.config and client.config.root_dir or "(no root)"
      add("  " .. client.name .. "  root: " .. tostring(root))
      has_clients = true
    end
  end
  if not has_clients then
    add("  (none attached)")
  end

  -- Formatters
  header("Formatters")
  local formatters = {}
  local ok_nls, nls = pcall(require, "null-ls")
  if ok_nls then
    local ok_methods, nls_methods = pcall(require, "null-ls.methods")
    local fmt_method = ok_methods and nls_methods.internal.FORMATTING or "NULL_LS_FORMATTING"
    for _, source in ipairs(nls.get_sources()) do
      if source.filetypes and source.filetypes[ft] then
        if source.methods and source.methods[fmt_method] then
          table.insert(formatters, source.name)
        end
      end
    end
  end
  for _, client in ipairs(clients) do
    if client.name ~= "null-ls" and client.name ~= "copilot" then
      if client:supports_method("textDocument/formatting") then
        table.insert(formatters, client.name .. " (LSP)")
      end
    end
  end
  if #formatters == 0 then
    add("  (none)")
  else
    for _, f in ipairs(formatters) do
      add("  " .. f)
    end
  end

  -- Linters
  header("Linters")
  local linters = {}
  if ok_nls then
    local ok_methods, nls_methods = pcall(require, "null-ls.methods")
    local diag_method = ok_methods and nls_methods.internal.DIAGNOSTICS or "NULL_LS_DIAGNOSTICS"
    for _, source in ipairs(nls.get_sources()) do
      if source.filetypes and source.filetypes[ft] then
        if source.methods and source.methods[diag_method] then
          table.insert(linters, source.name)
        end
      end
    end
  end
  for _, client in ipairs(clients) do
    if client.name ~= "null-ls" and client.name ~= "copilot" then
      if client:supports_method("textDocument/publishDiagnostics") then
        table.insert(linters, client.name .. " (LSP)")
      end
    end
  end
  if #linters == 0 then
    add("  (none)")
  else
    for _, l in ipairs(linters) do
      add("  " .. l)
    end
  end

  -- DAP adapter
  header("Debug Adapter")
  local ok_dap, dap = pcall(require, "dap")
  if ok_dap and dap.configurations[ft] then
    local configs = dap.configurations[ft]
    add("  " .. #configs .. " config(s) for " .. ft)
    if configs[1] and configs[1].type then
      add("  Adapter: " .. configs[1].type)
    end
  else
    add("  (none for " .. ft .. ")")
  end

  -- Treesitter
  header("Treesitter")
  local lang = vim.treesitter.language.get_lang(ft)
  if lang and pcall(vim.treesitter.language.inspect, lang) then
    add("  Parser: " .. lang .. " (installed)")
  elseif lang then
    add("  Parser: " .. lang .. " (NOT installed)")
  else
    add("  No parser mapping for " .. ft)
  end

  -- Display in floating window
  local width = 50
  for _, line in ipairs(lines) do
    if #line + 4 > width then
      width = #line + 4
    end
  end
  local height = #lines
  local float_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(float_buf, 0, -1, false, lines)
  vim.bo[float_buf].modifiable = false
  vim.bo[float_buf].bufhidden = "wipe"

  vim.api.nvim_open_win(float_buf, true, {
    relative = "editor",
    width = math.min(width, vim.o.columns - 4),
    height = math.min(height, vim.o.lines - 4),
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " LushInfo ",
    title_pos = "center",
  })

  vim.keymap.set("n", "q", "<CMD>close<CR>", { buffer = float_buf, nowait = true })
  vim.keymap.set("n", "<Esc>", "<CMD>close<CR>", { buffer = float_buf, nowait = true })
end, { desc = "Show current buffer tooling status" })

-- :LushStatus — high-level LushNvim status panel.
-- Shows config-level state at a glance: active colorscheme/statusline,
-- enabled feature count, registry sizes, lockfile presence, sub-section
-- snacks status. Sister of :LushInfo (buffer-specific) and :checkhealth
-- lush (deep diagnostic).
create_user_command("LushStatus", function()
  local utils = require("config.utils")
  local uc = utils.get_user_config()
  local lines = {}
  local function add(s)
    table.insert(lines, s)
  end
  local function section(s)
    add("")
    add("─── " .. s .. " ───")
  end

  add("=== LushStatus ===")

  section("Theme")
  add("  Colorscheme: " .. (vim.g.colors_name or "(default)"))
  local ok_styles, styles_mod = pcall(require, "lush.statuslines")
  if ok_styles and type(styles_mod.current) == "function" then
    add("  Statusline:  " .. tostring(styles_mod.current() or "(default)"))
  end

  section("Features")
  if uc.enable_plugins then
    local on, off = 0, 0
    for _, v in pairs(uc.enable_plugins) do
      if v == false then
        off = off + 1
      else
        on = on + 1
      end
    end
    add(string.format("  enable_plugins: %d on, %d off", on, off))
  end
  if uc.languages then
    add("  Language bundles: " .. table.concat(uc.languages, ", "))
  end

  section("Reload registries")
  add(
    string.format(
      "  Tracked keymaps: %d",
      type(_G.lush_tracked_keymaps) == "table" and #_G.lush_tracked_keymaps or 0
    )
  )
  add(
    string.format(
      "  Tracked options: %d",
      type(_G.lush_tracked_opts) == "table" and vim.tbl_count(_G.lush_tracked_opts) or 0
    )
  )

  section("snacks.nvim")
  local ok_snacks, snacks = pcall(require, "snacks")
  if ok_snacks then
    -- snacks.config has a metatable; iterate via enable_plugins.snacks_* keys.
    local enabled_mods = {}
    if uc.enable_plugins then
      for k, v in pairs(uc.enable_plugins) do
        if k:match("^snacks_") and (v == true or v == nil) then
          local module_name = k:gsub("^snacks_", "")
          local cfg = snacks.config and snacks.config[module_name]
          if cfg and cfg.enabled then
            table.insert(enabled_mods, module_name)
          end
        end
      end
    end
    table.sort(enabled_mods)
    add("  Enabled modules: " .. #enabled_mods)
    if #enabled_mods > 0 then
      add("  " .. table.concat(enabled_mods, ", "))
    end
  else
    add("  snacks not loaded")
  end

  section("LSP / DAP")
  add("  LSP clients: " .. #vim.lsp.get_clients())
  local ok_dap, dap = pcall(require, "dap")
  if ok_dap then
    local adapters = {}
    for k in pairs(dap.adapters or {}) do
      table.insert(adapters, k)
    end
    table.sort(adapters)
    add("  DAP adapters: " .. table.concat(adapters, ", "))
  end

  add("")
  add("(:checkhealth lush  for deep diagnostic)")

  -- Display in floating window (same style as LushInfo)
  local width = 50
  for _, line in ipairs(lines) do
    if #line + 4 > width then
      width = #line + 4
    end
  end
  local height = #lines
  local float_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(float_buf, 0, -1, false, lines)
  vim.bo[float_buf].modifiable = false
  vim.bo[float_buf].bufhidden = "wipe"

  vim.api.nvim_open_win(float_buf, true, {
    relative = "editor",
    width = math.min(width, vim.o.columns - 4),
    height = math.min(height, vim.o.lines - 4),
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " LushStatus ",
    title_pos = "center",
  })

  vim.keymap.set("n", "q", "<CMD>close<CR>", { buffer = float_buf, nowait = true })
  vim.keymap.set("n", "<Esc>", "<CMD>close<CR>", { buffer = float_buf, nowait = true })
end, { desc = "Show LushNvim config-level status panel" })

-- :LushHealth — convenience alias for :checkhealth lush (more discoverable).
create_user_command("LushHealth", function()
  vim.cmd("checkhealth lush")
end, { desc = "Run :checkhealth lush" })
