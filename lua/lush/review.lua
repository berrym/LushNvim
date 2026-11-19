-- Review what changed since a marked point.
--
-- Built for reviewing an agent's work after the fact (Claude Code in auto
-- mode edits and sometimes commits without asking). git on its own only
-- answers "what differs from the index", which mixes in your own uncommitted
-- edits and loses anything already committed. A review point is a snapshot of
-- the working tree taken with `git stash create`: a commit object that touches
-- neither the index, the stash list nor any ref.
--
--   mark()   snapshot now; gitsigns compares against it from then on
--   review() diffview of everything changed since the mark (files created
--            since then are named in the notification; diffview omits them)
--   hunks()  every changed hunk in the quickfix list, to step through with ]q
--   clear()  drop the mark; gitsigns compares against the index again
--
-- The mark lives in vim.g.lush_review_mark, so it survives :LushReload and is
-- gone when Neovim exits. It is one mark per session, not one per repository.

local utils = require("config.utils")
local group = utils.get_plugin_group()

local M = {}

local TITLE = "Review"

--- Run git in `dir`. Returns ok, trimmed stdout.
local function git(dir, args)
  local cmd = { "git", "-C", dir }
  vim.list_extend(cmd, args)
  local ok, res = pcall(function()
    return vim.system(cmd, { text = true }):wait()
  end)
  if not ok or res.code ~= 0 then
    return false, ""
  end
  return true, vim.trim(res.stdout or "")
end

--- Root of the repository holding the current file, else the cwd's.
local function repo_root()
  local dirs = {}
  local name = vim.api.nvim_buf_get_name(0)
  if vim.bo.buftype == "" and name ~= "" then
    dirs[#dirs + 1] = vim.fs.dirname(name)
  end
  dirs[#dirs + 1] = vim.fn.getcwd()
  for _, dir in ipairs(dirs) do
    if vim.fn.isdirectory(dir) == 1 then
      local ok, root = git(dir, { "rev-parse", "--show-toplevel" })
      if ok and root ~= "" then
        return root
      end
    end
  end
  return nil
end

--- Untracked, non-ignored files as a set of repo-relative paths.
local function untracked(root)
  local set = {}
  local ok, out = git(root, { "ls-files", "--others", "--exclude-standard" })
  if ok and out ~= "" then
    for _, path in ipairs(vim.split(out, "\n", { plain = true })) do
      set[path] = true
    end
  end
  return set
end

--- The mark, if one is set for `root` and its snapshot still exists.
local function mark_for(root)
  local mark = vim.g.lush_review_mark
  if type(mark) ~= "table" or mark.root ~= root then
    return nil
  end
  if not git(root, { "cat-file", "-e", mark.sha .. "^{commit}" }) then
    return nil
  end
  return mark
end

--- Repo-relative paths of files created since `mark` (every untracked file
--- when there is no mark), sorted.
local function new_files(root, mark)
  local known = {}
  for _, path in ipairs(mark and mark.untracked or {}) do
    known[path] = true
  end
  local paths = {}
  for path in pairs(untracked(root)) do
    if not known[path] then
      paths[#paths + 1] = path
    end
  end
  table.sort(paths)
  return paths
end

local function gitsigns()
  if not utils.enabled(group, "gitsigns") then
    return nil
  end
  local ok, gs = pcall(require, "gitsigns")
  return ok and gs or nil
end

--- Snapshot the working tree as the new review point.
function M.mark()
  local root = repo_root()
  if not root then
    utils.notify_warn("Not inside a git repository", TITLE)
    return
  end
  -- `stash create` prints nothing when the tree is clean; HEAD is the
  -- snapshot then.
  local ok, sha = git(root, { "stash", "create", "lush review point" })
  if not ok or sha == "" then
    ok, sha = git(root, { "rev-parse", "HEAD" })
  end
  if not ok or sha == "" then
    utils.notify_warn("Could not snapshot the working tree (no commits yet?)", TITLE)
    return
  end

  local time = os.date("%H:%M")
  vim.g.lush_review_mark = {
    sha = sha,
    root = root,
    time = time,
    untracked = vim.tbl_keys(untracked(root)),
  }

  local gs = gitsigns()
  if gs then
    gs.change_base(sha, true, function(err)
      if err then
        vim.schedule(function()
          utils.notify_warn(
            "gitsigns could not switch to the review point: " .. tostring(err),
            TITLE
          )
        end)
      end
    end)
  end
  utils.notify_info(
    "Review point set at " .. time .. ". Changes are now shown relative to it.",
    TITLE
  )
end

--- Drop the review point and return gitsigns to the index.
function M.clear()
  if vim.g.lush_review_mark == nil then
    utils.notify_info("No review point set", TITLE)
    return
  end
  vim.g.lush_review_mark = nil
  local gs = gitsigns()
  if gs then
    gs.reset_base(true)
  end
  utils.notify_info("Review point cleared. Changes are shown relative to the index again.", TITLE)
end

--- Toggle a diffview of everything changed since the review point (or of the
--- uncommitted changes when no point is set).
function M.review()
  if not utils.enabled(group, "diffview") then
    utils.notify_warn("diffview is disabled", TITLE)
    return
  end
  local ok, lib = pcall(require, "diffview.lib")
  if not ok then
    utils.notify_warn("diffview is not installed", TITLE)
    return
  end
  if lib.get_current_view() then
    vim.cmd.DiffviewClose()
    return
  end
  local root = repo_root()
  if not root then
    utils.notify_warn("Not inside a git repository", TITLE)
    return
  end
  local mark = mark_for(root)
  if mark then
    vim.cmd.DiffviewOpen(mark.sha)
    local msg = "Changes since the review point set at " .. mark.time
    -- diffview leaves untracked files out whenever it compares against a
    -- commit, so files created since the mark are named here instead.
    local created = new_files(root, mark)
    if #created > 0 then
      local shown = vim.list_slice(created, 1, 8)
      msg = msg
        .. "\nNew files, not in this view ("
        .. #created
        .. "):\n  "
        .. table.concat(shown, "\n  ")
      if #created > #shown then
        msg = msg .. "\n  ..."
      end
    end
    utils.notify_info(msg, TITLE)
  else
    vim.cmd.DiffviewOpen()
    utils.notify_info("No review point set: showing uncommitted changes", TITLE)
  end
end

--- Put every changed hunk into the quickfix list (step with ]q / [q). gitsigns
--- diffs against its base, which mark() points at the review point. Files
--- created since the mark are untracked, so gitsigns skips them; they are
--- appended as one entry each.
function M.hunks()
  local gs = gitsigns()
  if not gs then
    utils.notify_warn("gitsigns is disabled", TITLE)
    return
  end
  local root = repo_root()
  local mark = root and mark_for(root) or nil

  gs.setqflist("all", { open = false }, function(err)
    vim.schedule(function()
      if err then
        utils.notify_warn("Could not collect hunks: " .. tostring(err), TITLE)
        return
      end

      if root then
        local items = {}
        for _, path in ipairs(new_files(root, mark)) do
          items[#items + 1] = { filename = root .. "/" .. path, lnum = 1, text = "New file" }
        end
        if #items > 0 then
          vim.fn.setqflist({}, "a", { items = items })
        end
      end

      local count = #vim.fn.getqflist()
      local since = mark and ("the review point set at " .. mark.time) or "the index"
      if count == 0 then
        utils.notify_info("No changes since " .. since, TITLE)
        return
      end
      vim.fn.setqflist({}, "a", { title = "Changes since " .. since })

      local has_trouble, trouble = pcall(require, "trouble")
      if utils.enabled(group, "trouble") and has_trouble then
        trouble.open("qflist")
      else
        vim.cmd.copen()
      end
    end)
  end)
end

return M
