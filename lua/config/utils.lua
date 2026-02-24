local M = {}

-- OS detection helpers
M.is_mac = vim.fn.has("macunix") == 1
M.is_linux = vim.fn.has("unix") == 1 and not M.is_mac
M.is_windows = vim.fn.has("win32") == 1

-- sets main options from options (table)
M.vim_opts = function(options)
  if options ~= nil then
    for scope, table in pairs(options) do
      for setting, value in pairs(table) do
        vim[scope][setting] = value
      end
    end
  end
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

-- creates floating terminal for toggleterm
M.create_floating_terminal = function(terminal, cmd)
  local instance = nil
  if vim.fn.executable(cmd) == 1 then
    instance = terminal:new({
      cmd = cmd,
      dir = "git_dir",
      direction = "float",
      float_opts = {
        border = "rounded",
      },
      on_open = function(term)
        vim.cmd.startinsert()
        vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = term.bufnr, noremap = true, silent = true })
      end,
    })
  end
  -- check if TermExec function exists
  return function()
    if vim.fn.executable(cmd) == 1 and instance ~= nil then
      instance:toggle()
    else
      M.notify_error("Command not found: " .. cmd .. ". Ensure it is installed.")
    end
  end
end

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
  vim.fn.jobstart({ "git", "pull", "--rebase" })
  require("lazy").sync({ wait = true })
  M.notify_info("Updating Mason packages...")
  M.update_mason()
  -- Update treesitter parsers via command (stable across branches)
  vim.cmd("TSUpdate")
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

return M
