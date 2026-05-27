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
    "toggleterm",
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

-- Rewrite (or insert) a single flag line in user/config.lua.
local function persist_flag(name, new_value)
  local config_path = vim.fn.stdpath("config") .. "/lua/user/config.lua"
  local lines = vim.fn.readfile(config_path)
  if not lines or #lines == 0 then
    return nil
  end
  local esc = name:gsub("(%W)", "%%%1")
  local in_table = false
  for i, line in ipairs(lines) do
    if line:match("^%s*M%.enable_plugins%s*=%s*{") then
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
-- current state, and category so the displayer can show a header glyph.
local function build_entries()
  local flags = utils.get_user_config("enable_plugins") or {}
  local by_cat = {}
  for name, v in pairs(flags) do
    local cat = category_of(name)
    by_cat[cat] = by_cat[cat] or {}
    table.insert(by_cat[cat], {
      name = name,
      on = v == true or v == nil,
      category = cat,
    })
  end
  -- Flatten in category_order; alpha-sort within each.
  local entries = {}
  for _, cat in ipairs(category_order) do
    local list = by_cat[cat]
    if list then
      table.sort(list, function(a, b)
        return a.name < b.name
      end)
      for _, e in ipairs(list) do
        e.display = string.format(
          "[%-9s] %s %-28s %s",
          cat,
          e.on and "" or "",
          e.name,
          e.on and "(on)" or "(off)"
        )
        table.insert(entries, e)
      end
      by_cat[cat] = nil
    end
  end
  -- Any unknown category not in category_order
  for cat, list in pairs(by_cat) do
    table.sort(list, function(a, b)
      return a.name < b.name
    end)
    for _, e in ipairs(list) do
      e.display = string.format(
        "[%-9s] %s %-28s %s",
        cat,
        e.on and "" or "",
        e.name,
        e.on and "(on)" or "(off)"
      )
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

  -- Track multi-select marks (telescope's own multi-select is awkward for
  -- our use case; we keep our own set keyed by flag name).
  local marked = {}

  local function entry_display(e)
    local mark = marked[e.name] and "" or " "
    return string.format(
      "%s [%-9s] %s %-28s %s",
      mark,
      e.category,
      e.on and "" or "",
      e.name,
      e.on and "(on)" or "(off)"
    )
  end

  local function apply_and_reload(entries)
    local applied = 0
    for _, entry in ipairs(entries) do
      local new_value = not entry.on
      if persist_flag(entry.name, new_value) ~= nil then
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
      prompt_title = "Features  <CR>=toggle one  <Tab>=mark  <C-a>=apply marks",
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
        -- <CR>: toggle just the focused flag and reload.
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if not selection then
            return
          end
          apply_and_reload({ selection.value })
        end)

        -- <Tab>: mark/unmark current entry, refresh display.
        local function toggle_mark()
          local selection = action_state.get_selected_entry()
          if not selection then
            return
          end
          local name = selection.value.name
          marked[name] = not marked[name] or nil
          local picker = action_state.get_current_picker(prompt_bufnr)
          if picker then
            picker:refresh(nil, { reset_prompt = false })
          end
        end
        mapfn({ "i", "n" }, "<Tab>", toggle_mark)

        -- <C-a>: apply every marked entry in a single reload pass.
        local function apply_marked()
          local to_apply = {}
          for _, e in ipairs(build_entries()) do
            if marked[e.name] then
              table.insert(to_apply, e)
            end
          end
          actions.close(prompt_bufnr)
          if #to_apply == 0 then
            utils.notify_info("No marks — press <Tab> on flags first", "Features")
            return
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
