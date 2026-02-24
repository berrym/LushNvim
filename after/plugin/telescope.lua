local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "telescope") then
  local telescope = require("telescope")
  telescope.setup({
    defaults = {
      file_ignore_patterns = { "node_modules", ".git/" },
    },
    pickers = {
      find_files = {
        hidden = true,
      },
      git_files = {
        show_untracked = true,
      },
    },
  })
  if utils.enabled(group, "scope") then
    telescope.load_extension("scope")
  end
  if utils.enabled(group, "aerial") then
    telescope.load_extension("aerial")
  end
  if utils.enabled(group, "notify") then
    telescope.load_extension("notify")
  end
  if utils.enabled(group, "noice") then
    telescope.load_extension("noice")
  end
  if utils.enabled(group, "projects") then
    telescope.load_extension("projects")
  end

  -- Custom project picker: cd to project, restore session or open fresh workspace
  -- Used by alpha dashboard "Open project" button
  _G.telescope_open_project = function()
    local history = require("project_nvim.utils.history")
    local project = require("project_nvim.project")
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local entry_display = require("telescope.pickers.entry_display")

    local results = history.get_recent_projects()
    for i = 1, math.floor(#results / 2) do
      results[i], results[#results - i + 1] = results[#results - i + 1], results[i]
    end

    local displayer = entry_display.create({
      separator = " ",
      items = { { width = 30 }, { remaining = true } },
    })

    pickers.new({}, {
      prompt_title = "Open Project",
      finder = finders.new_table({
        results = results,
        entry_maker = function(entry)
          local name = vim.fn.fnamemodify(entry, ":t")
          return {
            display = function(e) return displayer({ e.name, { e.value, "Comment" } }) end,
            name = name,
            value = entry,
            ordinal = name .. " " .. entry,
          }
        end,
      }),
      previewer = false,
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selected = state.get_selected_entry(prompt_bufnr)
          actions.close(prompt_bufnr)
          if not selected then return end

          -- cd to project
          project.set_pwd(selected.value, "telescope")

          -- Try to restore session for this project
          local ok_sm, sm = pcall(require, "session_manager")
          if ok_sm and sm.load_current_dir_session() then
            return -- session restored with full state
          end

          -- No session: open scratch buffer + neo-tree for IDE-like view
          vim.cmd("enew")
          if utils.enabled(group, "neotree") then
            vim.cmd("Neotree toggle left")
          end
        end)
        return true
      end,
    }):find()
  end
end
