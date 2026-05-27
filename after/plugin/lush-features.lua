-- :LushFeatures — picker for toggling enable_plugins flags with persistence.
-- <CR> toggles the selected flag, rewrites lua/user/config.lua in place, then
-- fires :LushReload so the change is live. Mirrors lush-colors / lush-statusline.

local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "telescope") then
  -- Toggle the flag's value (true↔false) by rewriting the matching line in
  -- user/config.lua. If the flag isn't present in the file, insert it at the
  -- end of the M.enable_plugins table. Returns the new boolean value.
  local function persist_toggle(name, new_value)
    local config_path = vim.fn.stdpath("config") .. "/lua/user/config.lua"
    local lines = vim.fn.readfile(config_path)
    if not lines or #lines == 0 then
      return nil
    end

    -- Escape Lua-pattern magic chars in the flag name (snacks_indent, dap_js, etc.
    -- only contain word chars, but be defensive in case future flags add them).
    local esc = name:gsub("(%W)", "%%%1")
    local in_table = false

    for i, line in ipairs(lines) do
      if line:match("^%s*M%.enable_plugins%s*=%s*{") then
        in_table = true
      elseif in_table then
        if line:match("^%s*}%s*$") then
          -- Reached the closing brace without finding the flag; insert just before.
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

  -- Build the picker entries from the live enable_plugins table, sorted
  -- alphabetically. Each entry carries the flag name and current state.
  local function build_entries()
    local flags = utils.get_user_config("enable_plugins") or {}
    local names = {}
    for k in pairs(flags) do
      table.insert(names, k)
    end
    table.sort(names)

    local entries = {}
    for _, name in ipairs(names) do
      local on = flags[name] == true or flags[name] == nil
      table.insert(entries, {
        name = name,
        on = on,
        display = string.format("  %s %-28s %s", on and "" or "", name, on and "(on)" or "(off)"),
      })
    end
    return entries
  end

  _G.lush_features_pick = function()
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values

    pickers
      .new({}, {
        prompt_title = "Features  <CR>=toggle & reload  <Esc>=cancel",
        finder = finders.new_table({
          results = build_entries(),
          entry_maker = function(e)
            return {
              display = e.display,
              value = e,
              ordinal = e.name,
            }
          end,
        }),
        previewer = false,
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, _)
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if not selection then
              return
            end
            local entry = selection.value
            local new_value = not entry.on
            local persisted = persist_toggle(entry.name, new_value)
            if persisted == nil then
              utils.notify_warn(
                "Could not persist " .. entry.name .. " — user/config.lua unreadable?",
                "Features"
              )
              return
            end
            local state = new_value and "enabled" or "disabled"
            utils.notify_info(entry.name .. " " .. state .. " — reloading", "Features")
            -- Reload so the new state takes effect immediately.
            vim.schedule(function()
              pcall(vim.cmd, "LushReload")
            end)
          end)
          return true
        end,
      })
      :find()
  end

  vim.api.nvim_create_user_command("LushFeatures", function()
    lush_features_pick()
  end, { desc = "Toggle enable_plugins flags with persistence and reload" })
end
