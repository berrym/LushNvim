-- Statusline picker with live preview and persistence.
-- Mirrors the lush-colors.lua pattern: Telescope picker, <CR> confirms and writes
-- the chosen style to user/config.lua, cancel restores the original style.

local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "telescope") and utils.enabled(group, "lualine") then
  local styles_mod = require("lush.statuslines")

  -- Persist choice to user/config.lua by rewriting the active utils.statusline(...) line.
  local function persist_statusline(name)
    local config_path = vim.fn.stdpath("config") .. "/lua/user/config.lua"
    local lines = vim.fn.readfile(config_path)
    if not lines or #lines == 0 then
      return false
    end

    local pattern = 'utils%.statusline%(".-"%)'
    local replacement = 'utils.statusline("' .. name .. '")'

    for i, line in ipairs(lines) do
      if line:match("^%s*utils%.statusline%(") and not line:match("^%s*%-%-") then
        lines[i] = line:gsub(pattern, replacement)
        vim.fn.writefile(lines, config_path)
        return true
      end
    end

    -- Fallback: insert a new utils.statusline(...) call just after utils.colors(...).
    for i, line in ipairs(lines) do
      if line:match("^%s*utils%.colors%(") and not line:match("^%s*%-%-") then
        local indent = line:match("^(%s*)") or ""
        table.insert(lines, i + 1, indent .. replacement)
        vim.fn.writefile(lines, config_path)
        return true
      end
    end
    return false
  end

  _G.lush_statusline_pick = function()
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values

    local original = styles_mod.current()
    local need_restore = true

    local picker = pickers.new({}, {
      prompt_title = "Statusline  <CR>=apply & persist  <Esc>=cancel",
      finder = finders.new_table({
        results = styles_mod.list(),
        entry_maker = function(entry)
          return {
            display = string.format("%-12s  %s", entry.label, entry.blurb),
            value = entry,
            ordinal = entry.name .. " " .. entry.label,
          }
        end,
      }),
      previewer = false,
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          need_restore = false
          actions.close(prompt_bufnr)
          if not selection then
            return
          end
          styles_mod.apply(selection.value.name)
          local persisted = persist_statusline(selection.value.name)
          local msg = selection.value.label
            .. (
              persisted and ""
              or ' (not persisted — add utils.statusline("'
                .. selection.value.name
                .. '") to user/config.lua)'
            )
          utils.notify_info(msg, "Statusline")
        end)
        return true
      end,
    })

    -- Live preview on cursor move.
    local original_set_selection = picker.set_selection
    picker.set_selection = function(self, row)
      original_set_selection(self, row)
      local selection = action_state.get_selected_entry()
      if selection then
        styles_mod.apply(selection.value.name)
      end
    end

    -- Restore previous style on cancel.
    local original_close_windows = picker.close_windows
    picker.close_windows = function(status)
      original_close_windows(status)
      if need_restore then
        styles_mod.apply(original)
      end
    end

    picker:find()
  end

  vim.api.nvim_create_user_command("LushStatusline", function()
    lush_statusline_pick()
  end, { desc = "Pick lualine style with live preview and persistence" })
end
