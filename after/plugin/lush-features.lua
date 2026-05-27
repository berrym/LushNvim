-- :LushFeatures — picker for toggling enable_plugins flags with persistence.
--
-- Flags are grouped by category (Editor / LSP / UI / Languages / snacks / DAP /
-- AI) for navigation as the flag count grows.
--
-- Selection modes:
--   <CR>   — toggle the current flag, persist, reload (single-shot)
--   <Tab>  — mark / unmark for batch toggle
--   <C-a>  — apply all marked flags, persist, reload once

local utils = require("config.utils")
local group = utils.get_plugin_group()

if not utils.enabled(group, "telescope") then
  return
end

-- Short human-readable descriptions per flag. Anything missing falls back
-- to a generic "" hint — keep the table small and let truly obvious flags
-- (e.g. snacks_X — covered by the snacks.nvim cluster docs) stay blank.
local descriptions = {
  aerial = "Code outline window",
  autopairs = "Auto-close () [] {} '' \"\"",
  autotag = "Auto-close/rename HTML/JSX tags",
  bufferline = "Tab-style buffer line at the top",
  claudecode = "Claude Code AI assistant",
  cmp = "Completion (blink.cmp)",
  colorizer = "Inline color preview for hex/rgb",
  context = "Sticky context header (treesitter)",
  copilot = "GitHub Copilot suggestions",
  dap = "Debug Adapter Protocol",
  dap_go = "Go DAP integration (nvim-dap-go)",
  dap_js = "JS/TS DAP integration (js-debug)",
  dap_python = "Python DAP integration (debugpy)",
  diffview = "Side-by-side diff view (:DiffviewOpen)",
  flash = "Jump motions (s/S) with treesitter labels",
  gitsigns = "Hunk signs in the gutter",
  img_clip = "Paste images from clipboard",
  lazydev = "Lua LSP enrichment for nvim/luvit",
  lsp = "Language Server Protocol (vim.lsp.config)",
  lualine = "Statusline framework",
  neotree = "File explorer sidebar",
  noice = "Cmdline popup + LSP progress UI",
  notify = "Floating notifications (nvim-notify)",
  null_ls = "Formatter/linter aggregator (none-ls)",
  package_info = "Inline npm package versions",
  persistent_breakpoints = "Save/restore DAP breakpoints across sessions",
  project = "Project root detection + recent projects",
  rainbow = "Rainbow-colored brackets",
  rustaceanvim = "Rust LSP/debug bundle",
  schemastore = "JSON schema catalog for jsonls",
  scope = "Per-tab buffer scoping",
  session_manager = "Auto save/load sessions (persisted.nvim)",
  snacks = "Master toggle for the snacks.nvim cluster",
  telescope = "Fuzzy picker for files/buffers/grep/etc.",
  template_string = "Auto JS/TS backtick conversion",
  treesitter = "Syntax-aware highlighting + folds",
  trouble = "Diagnostics/quickfix tree view",
  ts_error_translator = "Plain-English TS error messages",
  ufo = "Fancier code folding (nvim-ufo)",
  whichkey = "Keymap hint popup",
  -- M.autocommands
  auto_reload = "checktime on focus + change notifications",
  autochdir = "Custom CWD management via vim.fs.root",
  claude_code_reload = "Aggressive reload for Claude-edited buffers",
  css_colorizer = "CSS-specific color preview",
  format_on_save = "BufWritePre → vim.lsp.buf.format",
  remember_file_state = "Restore cursor/folds via mkview",
  session_saved_notification = "Toast when persisted saves",
  treesitter_folds = "Use treesitter for foldexpr",
  whitespace_cleanup = "Strip trailing whitespace on save",
}

-- Manual category mapping. Anything not listed falls into "Other".
local categories = {
  Editor = {
    "autopairs",
    "autotag",
    "bufferline",
    "colorizer",
    "diffview",
    "flash",
    "gitsigns",
    "img_clip",
    "lazydev",
    "neotree",
    "noice",
    "notify",
    "project",
    "rainbow",
    "scope",
    "session_manager",
    "telescope",
    "treesitter",
    "trouble",
    "ufo",
    "whichkey",
    "context",
  },
  LSP = { "cmp", "copilot", "lsp", "null_ls" },
  UI = { "aerial", "lualine" },
  DAP = { "dap", "dap_python", "dap_go", "dap_js", "persistent_breakpoints" },
  AI = { "claudecode" },
  Languages = {
    "rustaceanvim",
    "package_info",
    "ts_error_translator",
    "template_string",
    "schemastore",
  },
  -- snacks_* flags are auto-grouped below; "snacks" master toggle stays in Editor.
}

local function category_of(name)
  if name:match("^snacks_") or name == "snacks" then
    return "snacks"
  end
  for cat, names in pairs(categories) do
    for _, n in ipairs(names) do
      if n == name then
        return cat
      end
    end
  end
  return "Other"
end

-- Category sort order in the picker.
local category_order = { "Editor", "LSP", "UI", "snacks", "Languages", "DAP", "AI", "Other" }

-- Rewrite (or insert) a single flag line in user/config.lua inside the
-- specified table ("enable_plugins" or "autocommands").
local function persist_flag(table_name, name, new_value)
  local config_path = vim.fn.stdpath("config") .. "/lua/user/config.lua"
  local lines = vim.fn.readfile(config_path)
  if not lines or #lines == 0 then
    return nil
  end
  local esc = name:gsub("(%W)", "%%%1")
  local table_pat = "^%s*M%." .. table_name .. "%s*=%s*{"
  local in_table = false
  for i, line in ipairs(lines) do
    if line:match(table_pat) then
      in_table = true
    elseif in_table then
      if line:match("^%s*}%s*$") then
        table.insert(lines, i, "  " .. name .. " = " .. tostring(new_value) .. ",")
        vim.fn.writefile(lines, config_path)
        return new_value
      end
      local indent, value = line:match("^(%s*)" .. esc .. "%s*=%s*(%w+)%s*,?")
      if indent and (value == "true" or value == "false") and not line:match("^%s*%-%-") then
        lines[i] = indent .. name .. " = " .. tostring(new_value) .. ","
        vim.fn.writefile(lines, config_path)
        return new_value
      end
    end
  end
  return nil
end

-- Build entries grouped by category. Each entry carries the flag name,
-- source table, current state, and category so the displayer can group them.
local function build_entries()
  local plugin_flags = utils.get_user_config("enable_plugins") or {}
  local autocmd_flags = utils.get_user_config("autocommands") or {}
  local by_cat = {}

  local function add(table_name, name, value)
    local cat = (table_name == "autocommands") and "Behavior" or category_of(name)
    by_cat[cat] = by_cat[cat] or {}
    table.insert(by_cat[cat], {
      name = name,
      on = value == true or value == nil,
      category = cat,
      table_name = table_name,
    })
  end
  for name, v in pairs(plugin_flags) do
    add("enable_plugins", name, v)
  end
  for name, v in pairs(autocmd_flags) do
    add("autocommands", name, v)
  end

  -- Flatten in category_order; alpha-sort within each.
  local order = { "Editor", "LSP", "UI", "snacks", "Languages", "DAP", "AI", "Behavior", "Other" }
  local entries = {}
  for _, cat in ipairs(order) do
    local list = by_cat[cat]
    if list then
      table.sort(list, function(a, b)
        return a.name < b.name
      end)
      for _, e in ipairs(list) do
        table.insert(entries, e)
      end
      by_cat[cat] = nil
    end
  end
  -- Any unknown category not in `order`
  for _, list in pairs(by_cat) do
    table.sort(list, function(a, b)
      return a.name < b.name
    end)
    for _, e in ipairs(list) do
      table.insert(entries, e)
    end
  end
  return entries
end

_G.lush_features_pick = function()
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values

  local function entry_display(e)
    local desc = descriptions[e.name] or ""
    return string.format(
      "[%-9s] %s %-28s %-5s %s",
      e.category,
      e.on and "" or "",
      e.name,
      e.on and "(on)" or "(off)",
      desc
    )
  end

  local function apply_and_reload(entries)
    local applied = 0
    for _, entry in ipairs(entries) do
      local new_value = not entry.on
      if persist_flag(entry.table_name, entry.name, new_value) ~= nil then
        applied = applied + 1
      end
    end
    if applied == 0 then
      utils.notify_warn("No flags persisted", "Features")
      return
    end
    utils.notify_info(
      string.format("Toggled %d flag%s — reloading", applied, applied == 1 and "" or "s"),
      "Features"
    )
    vim.schedule(function()
      pcall(vim.cmd, "LushReload")
    end)
  end

  pickers
    .new({}, {
      prompt_title = "Features  <CR>=toggle one  <Tab>=mark  <C-a>=toggle marked",
      finder = finders.new_table({
        results = build_entries(),
        entry_maker = function(e)
          return {
            display = entry_display(e),
            value = e,
            ordinal = e.category .. " " .. e.name,
          }
        end,
      }),
      previewer = false,
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, mapfn)
        -- <CR>: if any items are multi-selected (via telescope's built-in
        -- <Tab>), toggle all of them; otherwise toggle just the focused one.
        actions.select_default:replace(function()
          local picker = action_state.get_current_picker(prompt_bufnr)
          local multi = picker and picker:get_multi_selection() or {}
          actions.close(prompt_bufnr)
          if #multi > 0 then
            local to_apply = {}
            for _, sel in ipairs(multi) do
              table.insert(to_apply, sel.value)
            end
            apply_and_reload(to_apply)
            return
          end
          local selection = action_state.get_selected_entry()
          if not selection then
            return
          end
          apply_and_reload({ selection.value })
        end)

        -- <C-a>: explicit "apply marks" — same as <CR> when marks exist,
        -- but errors loudly when no marks are set so the user knows why.
        local function apply_marked()
          local picker = action_state.get_current_picker(prompt_bufnr)
          local multi = picker and picker:get_multi_selection() or {}
          if #multi == 0 then
            utils.notify_info("No marks — <Tab> on flags first, then <CR>", "Features")
            return
          end
          actions.close(prompt_bufnr)
          local to_apply = {}
          for _, sel in ipairs(multi) do
            table.insert(to_apply, sel.value)
          end
          apply_and_reload(to_apply)
        end
        mapfn({ "i", "n" }, "<C-a>", apply_marked)

        return true
      end,
    })
    :find()
end

vim.api.nvim_create_user_command("LushFeatures", function()
  lush_features_pick()
end, { desc = "Toggle enable_plugins flags with persistence and reload" })
