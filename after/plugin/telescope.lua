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
  pcall(function() telescope.load_extension("ui-select") end)
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
  if utils.enabled(group, "project") then
    pcall(telescope.load_extension, "projects")
  end
  if utils.enabled(group, "session_manager") then
    pcall(telescope.load_extension, "persisted")
  end

  -- Session picker: delegates to persisted.nvim's telescope extension
  -- Provides load (<CR>), delete (<C-d>), and branch switch (<C-b>)
  _G.telescope_session_pick = function()
    local ok = pcall(require("telescope").extensions.persisted.persisted)
    if not ok then utils.notify_warn("persisted.nvim not available", "Session") end
  end

  -- Custom project picker: cd to project, restore session or open fresh workspace
  -- Shows (session) indicator for projects that have saved sessions
  -- Actions:
  --   <CR>    Restore session (or fresh workspace if no session exists)
  --   <C-n>   Open project as fresh/clean workspace (ignore saved session)
  --   <C-d>   Delete saved session for project
  -- "Empty workspace" at top opens a blank slate with no project CWD
  -- Used by alpha dashboard "Open project" button and <leader>fp
  _G.telescope_open_project = function()
    local ok_proj, proj_history = pcall(require, "project.utils.history")
    if not ok_proj then
      -- Fallback for DrKJeff16 fork API differences
      ok_proj, proj_history = pcall(require, "project_nvim.utils.history")
    end
    if not ok_proj then
      utils.notify_warn("project.nvim not available", "Project")
      return
    end

    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local entry_display = require("telescope.pickers.entry_display")

    -- Build set of directories that have persisted sessions (only for live branches)
    local session_dirs = {}
    local stale_sessions = {} -- session files for deleted branches, cleaned up automatically
    local ok_persisted, persisted = pcall(require, "persisted")
    if ok_persisted then
      local sessions = persisted.list() or {}
      for _, session_path in ipairs(sessions) do
        -- persisted session filenames encode the directory: %%home%%user%%project@@branch.vim
        local fname = vim.fn.fnamemodify(session_path, ":t:r")
        local dir_part = fname:gsub("@@.*$", "")
        local dir = dir_part:gsub("%%%%", "/")

        -- Project directory gone entirely → stale session, clean up
        if vim.fn.isdirectory(dir) == 0 then
          table.insert(stale_sessions, session_path)
        else
          -- Extract branch name if present
          local branch_part = fname:match("@@(.+)$")
          local branch = branch_part and branch_part:gsub("%%%%", "/") or nil

          -- Verify branch still exists in the repo
          -- Branchless sessions (no @@) or non-git dirs are always valid
          local is_valid = true
          if branch and vim.fn.isdirectory(dir .. "/.git") == 1 then
            vim.fn.system("git -C " .. vim.fn.shellescape(dir)
              .. " rev-parse --verify --quiet refs/heads/" .. vim.fn.shellescape(branch)
              .. " 2>/dev/null")
            if vim.v.shell_error ~= 0 then
              is_valid = false
              table.insert(stale_sessions, session_path)
            end
          end

          if is_valid then
            session_dirs[dir] = true
          end
        end
      end
      -- Clean up stale session files for deleted branches / removed projects
      for _, path in ipairs(stale_sessions) do
        pcall(vim.fn.delete, path)
      end
    end

    -- Build project list, filtering out directories that no longer exist
    local all_projects = proj_history.get_recent_projects()
    local results = {}
    for i = #all_projects, 1, -1 do -- reverse to show most recent first
      if vim.fn.isdirectory(all_projects[i]) == 1 then
        table.insert(results, all_projects[i])
      end
    end
    table.insert(results, 1, "__empty__")

    -- Get current git branch for a directory (cached per picker invocation)
    local branch_cache = {}
    local function get_branch(dir)
      if branch_cache[dir] ~= nil then return branch_cache[dir] end
      local branch = vim.fn.system("git -C " .. vim.fn.shellescape(dir) .. " branch --show-current 2>/dev/null")
      branch = vim.trim(branch)
      branch_cache[dir] = branch ~= "" and branch or false
      return branch_cache[dir]
    end

    local displayer = entry_display.create({
      separator = " ",
      items = { { width = 24 }, { width = 16 }, { width = 16 }, { remaining = true } },
    })

    -- Open a project as a clean IDE workspace: scratch buffer + neo-tree, CWD set
    local function open_fresh_workspace(project_dir)
      if project_dir and project_dir ~= "__empty__" then
        vim.cmd("cd " .. vim.fn.fnameescape(project_dir))
      end
      -- Close all existing buffers for a truly clean slate
      vim.cmd("%bdelete!")
      vim.cmd("enew")
      if utils.enabled(group, "neotree") then
        vim.cmd("Neotree toggle left")
      end
      local name = project_dir and vim.fn.fnamemodify(project_dir, ":t") or "workspace"
      utils.notify_info(name .. " (fresh)", "Project")
    end

    -- Open a project and restore its saved session
    local function open_with_session(project_dir)
      vim.cmd("cd " .. vim.fn.fnameescape(project_dir))

      if ok_persisted then
        -- persisted.load() detects CWD + current branch automatically
        -- PersistedLoadPost autocmd in session.lua handles the notification
        local loaded = pcall(persisted.load)
        if loaded then return end
      end

      -- No session found: fall back to fresh workspace
      open_fresh_workspace(project_dir)
    end

    pickers.new({}, {
      prompt_title = "Projects  Enter=restore session  Ctrl-n=fresh workspace  Ctrl-d=delete session",
      finder = finders.new_table({
        results = results,
        entry_maker = function(entry)
          if entry == "__empty__" then
            return {
              display = function()
                return displayer({
                  "  Empty workspace",
                  { "", "Comment" },
                  { "", "Comment" },
                  { "", "Comment" },
                })
              end,
              name = "Empty workspace",
              value = "__empty__",
              ordinal = "empty workspace",
            }
          end
          local name = vim.fn.fnamemodify(entry, ":t")
          local branch = get_branch(entry)
          local branch_display = branch and (" " .. branch) or ""
          local has_session = session_dirs[entry]
          local tag = has_session and "(saved session)" or "(no session)"
          local hl = has_session and "String" or "Comment"
          return {
            display = function(e)
              return displayer({
                e.name,
                { branch_display, "Special" },
                { tag, hl },
                { e.value, "Comment" },
              })
            end,
            name = name,
            value = entry,
            ordinal = name .. " " .. entry,
          }
        end,
      }),
      previewer = false,
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        -- <CR>: restore session if available, otherwise fresh workspace
        actions.select_default:replace(function()
          local selected = state.get_selected_entry(prompt_bufnr)
          actions.close(prompt_bufnr)
          if not selected then return end

          if selected.value == "__empty__" then
            open_fresh_workspace(nil)
            return
          end

          if session_dirs[selected.value] then
            open_with_session(selected.value)
          else
            open_fresh_workspace(selected.value)
          end
        end)

        -- <C-n>: force fresh workspace (ignore any saved session)
        local function open_fresh()
          local selected = state.get_selected_entry()
          actions.close(prompt_bufnr)
          if not selected then return end
          open_fresh_workspace(selected.value ~= "__empty__" and selected.value or nil)
        end
        map("i", "<C-n>", open_fresh)
        map("n", "<C-n>", open_fresh)

        -- <C-d>: delete saved session
        local function delete_project_session()
          local selected = state.get_selected_entry()
          if not selected or selected.value == "__empty__" then return end

          if not ok_persisted then
            utils.notify_warn("persisted.nvim not available", "Session")
            return
          end

          local project_dir = selected.value
          local name = vim.fn.fnamemodify(project_dir, ":t")

          if not session_dirs[project_dir] then
            utils.notify_info("No session for " .. name, "Session")
            return
          end

          vim.ui.select({ "Yes", "No" }, { prompt = "Delete session for " .. name .. "?" }, function(choice)
            if choice ~= "Yes" then return end
            local sessions = persisted.list() or {}
            for _, session_path in ipairs(sessions) do
              local fname = vim.fn.fnamemodify(session_path, ":t:r")
              local dir_part = fname:gsub("@@.*$", "")
              local dir = dir_part:gsub("%%%%", "/")
              if dir == project_dir then
                pcall(vim.fn.delete, session_path)
              end
            end
            session_dirs[project_dir] = nil
            utils.notify_info("Deleted session: " .. name, "Session")

            local current_picker = state.get_current_picker(prompt_bufnr)
            if current_picker then
              current_picker:refresh(nil, { reset_prompt = false })
            end
          end)
        end
        map("i", "<C-d>", delete_project_session)
        map("n", "<C-d>", delete_project_session)

        return true
      end,
    }):find()
  end
end
