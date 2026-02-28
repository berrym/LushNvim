local create_user_command = vim.api.nvim_create_user_command
local colors = require("config.utils").colors

create_user_command("LushUpdate", function()
  require("config.utils").update_all()
end, { desc = "Updates plugins, mason packages, treesitter parsers" })

create_user_command("AstroTransparencyOn", function()
  require("astrotheme").setup({
    style = { transparent = true },
  })
  colors("astromars")
end, { desc = "Enable astrotheme transparency" })

create_user_command("AstroTransparencyOff", function()
  require("astrotheme").setup({
    style = { transparent = false },
  })
  colors("astromars")
end, { desc = "Disable astrotheme transparency" })

create_user_command("IblRainbowOn", function()
  require("ibl").setup({ indent = { highlight = _G.ibl_rainbow_highlight } })
end, { desc = "Enable colored indent markers" })

create_user_command("IblRainbowOff", function()
  require("ibl").setup()
end, { desc = "Disable colored indent markers" })

-- Hot-reload safe config components (options, keymaps, autocommands)
create_user_command("LushReload", function()
  local utils = require("config.utils")
  local reloaded = {}
  local failed = {}

  -- Modules that are safe to reload
  local safe_modules = {
    "config.options",
    "config.keybindings",
    "config.autocommands",
    "user.config",
  }

  for _, module in ipairs(safe_modules) do
    -- Clear from cache
    package.loaded[module] = nil
    -- Attempt to reload
    local ok, err = pcall(require, module)
    if ok then
      table.insert(reloaded, module)
    else
      table.insert(failed, module .. ": " .. tostring(err))
    end
  end

  -- Re-apply user options if user.config loaded
  local user_ok, user_config = pcall(require, "user.config")
  if user_ok and type(user_config) == "table" and user_config.options then
    utils.vim_opts(user_config.options)
  end

  -- Report results
  if #failed > 0 then
    utils.notify_error("Failed to reload:\n" .. table.concat(failed, "\n"), "LushReload")
  end
  if #reloaded > 0 then
    utils.notify_info("Reloaded: " .. table.concat(reloaded, ", "), "LushReload")
  end
end, { desc = "Hot-reload safe config components (options, keymaps, autocommands)" })

-- Show current buffer tooling status in a floating window
create_user_command("LushInfo", function()
  local buf = vim.api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype
  local bufname = vim.api.nvim_buf_get_name(buf)

  local lines = {}
  local function add(text) table.insert(lines, text) end
  local function header(text) add(""); add("--- " .. text .. " ---") end

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
  if #formatters == 0 then add("  (none)") else
    for _, f in ipairs(formatters) do add("  " .. f) end
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
  if #linters == 0 then add("  (none)") else
    for _, l in ipairs(linters) do add("  " .. l) end
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
    if #line + 4 > width then width = #line + 4 end
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
