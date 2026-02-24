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

  -- Custom session picker: load or delete sessions via telescope
  _G.telescope_session_pick = function()
    local ok_sm, _ = pcall(require, "session_manager")
    if not ok_sm then return end
    local sm_utils = require("session_manager.utils")
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local entry_display = require("telescope.pickers.entry_display")

    local function get_sessions()
      local sessions = sm_utils.get_sessions({ silent = true })
      return sessions or {}
    end

    local displayer = entry_display.create({
      separator = " ",
      items = { { width = 30 }, { remaining = true } },
    })

    local function make_finder(sessions)
      return finders.new_table({
        results = sessions,
        entry_maker = function(session)
          local dir = session.dir.filename or tostring(session.dir)
          local name = vim.fn.fnamemodify(dir, ":t")
          return {
            display = function(e) return displayer({ e.name, { dir, "Comment" } }) end,
            name = name,
            value = session,
            ordinal = name .. " " .. dir,
          }
        end,
      })
    end

    local sessions = get_sessions()

    pickers.new({}, {
      prompt_title = "Sessions  <C-d> delete",
      finder = make_finder(sessions),
      previewer = false,
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        -- Load session on enter
        actions.select_default:replace(function()
          local selected = state.get_selected_entry()
          actions.close(prompt_bufnr)
          if not selected then return end

          local dir = selected.value.dir.filename or tostring(selected.value.dir)
          vim.cmd("cd " .. vim.fn.fnameescape(dir))
          sm_utils.load_session(selected.value.filename, false)
        end)

        -- Delete session with <C-d>
        local function delete_selected()
          local selected = state.get_selected_entry()
          if not selected then return end

          local dir = selected.value.dir.filename or tostring(selected.value.dir)
          local name = vim.fn.fnamemodify(dir, ":t")
          vim.ui.select({ "Yes", "No" }, { prompt = "Delete session for " .. name .. "?" }, function(choice)
            if choice ~= "Yes" then return end
            sm_utils.delete_session(selected.value.filename)
            utils.notify_info("Deleted session: " .. name, "Session")

            -- Refresh picker with updated session list
            local current_picker = state.get_current_picker(prompt_bufnr)
            sessions = get_sessions()
            current_picker:refresh(make_finder(sessions), { reset_prompt = false })
          end)
        end
        map("i", "<C-d>", delete_selected)
        map("n", "<C-d>", delete_selected)

        return true
      end,
    }):find()
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
      prompt_title = "Open Project  <C-d> delete session",
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
      attach_mappings = function(prompt_bufnr, map)
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

        -- Delete session for selected project with <C-d>
        local function delete_project_session()
          local selected = state.get_selected_entry()
          if not selected then return end

          local ok_sm = pcall(require, "session_manager")
          if not ok_sm then return end
          local sm_utils = require("session_manager.utils")

          local project_dir = selected.value
          local name = vim.fn.fnamemodify(project_dir, ":t")

          -- Find session matching this project directory
          local sessions = sm_utils.get_sessions({ silent = true }) or {}
          local target = nil
          for _, session in ipairs(sessions) do
            local dir = session.dir.filename or tostring(session.dir)
            if dir == project_dir then
              target = session
              break
            end
          end

          if not target then
            utils.notify_info("No session for " .. name, "Session")
            return
          end

          vim.ui.select({ "Yes", "No" }, { prompt = "Delete session for " .. name .. "?" }, function(choice)
            if choice ~= "Yes" then return end
            sm_utils.delete_session(target.filename)
            utils.notify_info("Deleted session: " .. name, "Session")
          end)
        end
        map("i", "<C-d>", delete_project_session)
        map("n", "<C-d>", delete_project_session)

        return true
      end,
    }):find()
  end
end
