-- nvim-dap setup. Moved out of lazy.lua so :LushReload re-runs it cleanly.
--
-- The nvim-dap plugin spec keeps `keys = {...}` as lazy-load triggers, but in
-- practice dap is loaded eagerly anyway because lualine's "nvim-dap-ui"
-- extension requires it via the require chain at startup. So we just call
-- require + setup directly — wrapped in pcall so disabling DAP via
-- enable_plugins still works cleanly.

local utils = require("config.utils")
local group = utils.get_plugin_group()

if not utils.enabled(group, "dap") then
  return
end

local function setup_dap()
  local dap = require("dap")
  local pgroup = utils.get_plugin_group()

  -- ══════════════════════════════════════════════════════════════════
  -- [1] mason-nvim-dap: auto-configure ALL installed debug adapters
  -- Ensure mason.setup() has run first so its bin/ is on PATH
  -- (nvim-dap config may fire before lsp.lua's mason.setup call)
  -- ══════════════════════════════════════════════════════════════════
  pcall(function()
    require("mason").setup()
  end)

  local ok_mason_dap, mason_dap = pcall(require, "mason-nvim-dap")
  if ok_mason_dap then
    local user_config = utils.get_user_config()
    local sources = user_config.mason_ensure_installed and user_config.mason_ensure_installed.dap
      or {}
    mason_dap.setup({
      ensure_installed = sources,
      automatic_installation = true,
      handlers = {
        -- Default: auto-configure all installed adapters
        function(config)
          mason_dap.default_setup(config)
        end,
        -- Python: configured by nvim-dap-python in after/plugin/python.lua
        python = function() end,
        -- Go: configured by nvim-dap-go in after/plugin/go.lua
        delve = function() end,
      },
    })
  end

  -- ══════════════════════════════════════════════════════════════════
  -- [1b] Explicit adapter/config registration (LazyVim pattern)
  -- Guarantees C/C++/Rust work regardless of mason-nvim-dap timing
  -- ══════════════════════════════════════════════════════════════════
  dap.adapters["codelldb"] = {
    type = "server",
    port = "${port}",
    executable = {
      command = vim.fn.exepath("codelldb"),
      args = { "--port", "${port}" },
    },
  }

  -- Ignore noisy non-error signals that flood interactive programs.
  -- The signals are still passed to the program (-p true), just don't
  -- pause the debugger (-s false). Error signals (SIGSEGV, SIGABRT,
  -- SIGFPE, SIGBUS) are unaffected and will still stop as expected.
  local codelldb_pre = {
    "process handle SIGCHLD -n true -p true -s false",
    "process handle SIGWINCH -n true -p true -s false",
  }

  local codelldb_launch = {
    {
      type = "codelldb",
      request = "launch",
      name = "Launch file",
      program = function()
        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
      end,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
      preRunCommands = codelldb_pre,
    },
    {
      type = "codelldb",
      request = "launch",
      name = "Launch file (with args)",
      program = function()
        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
      end,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
      args = function()
        return vim.split(vim.fn.input("Args: "), " +", { trimempty = true })
      end,
      preRunCommands = codelldb_pre,
    },
    {
      type = "codelldb",
      request = "attach",
      name = "Attach to process",
      pid = require("dap.utils").pick_process,
      cwd = "${workspaceFolder}",
      preRunCommands = codelldb_pre,
    },
  }

  for _, lang in ipairs({ "c", "cpp", "rust" }) do
    -- Replace whatever mason-nvim-dap registered with our known-good configs
    dap.configurations[lang] = codelldb_launch
  end

  -- ══════════════════════════════════════════════════════════════════
  -- [2] Signs and highlights
  -- ══════════════════════════════════════════════════════════════════
  local function set_dap_highlights()
    vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#e51400" })
    vim.api.nvim_set_hl(0, "DapBreakpointCondition", { fg = "#f9a825" })
    vim.api.nvim_set_hl(0, "DapLogPoint", { fg = "#51afef" })
    vim.api.nvim_set_hl(0, "DapStopped", { fg = "#98be65" })
    vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#2e3d19" })
    vim.api.nvim_set_hl(0, "DapBreakpointRejected", { fg = "#656565" })
  end
  set_dap_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("lush_dap_highlights", { clear = true }),
    callback = set_dap_highlights,
  })

  vim.fn.sign_define(
    "DapBreakpoint",
    { text = "●", texthl = "DapBreakpoint", numhl = "DapBreakpoint" }
  )
  vim.fn.sign_define(
    "DapBreakpointCondition",
    { text = "◉", texthl = "DapBreakpointCondition", numhl = "DapBreakpointCondition" }
  )
  vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DapLogPoint", numhl = "DapLogPoint" })
  vim.fn.sign_define(
    "DapStopped",
    { text = "▶", texthl = "DapStopped", linehl = "DapStoppedLine", numhl = "DapStopped" }
  )
  vim.fn.sign_define(
    "DapBreakpointRejected",
    { text = "○", texthl = "DapBreakpointRejected", numhl = "DapBreakpointRejected" }
  )

  -- ══════════════════════════════════════════════════════════════════
  -- [3] DAP UI
  -- ══════════════════════════════════════════════════════════════════
  local ok_dapui, dapui = pcall(require, "dapui")
  if ok_dapui then
    dapui.setup({
      icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
      layouts = {
        {
          elements = {
            { id = "watches", size = 0.15 },
            { id = "stacks", size = 0.20 },
            { id = "breakpoints", size = 0.15 },
            { id = "scopes", size = 0.50 },
          },
          position = "left",
          size = 45,
        },
        {
          elements = {
            { id = "repl", size = 0.50 },
            { id = "console", size = 0.50 },
          },
          position = "bottom",
          size = 12,
        },
      },
      floating = { border = "rounded", mappings = { close = { "q", "<Esc>" } } },
      controls = {
        enabled = true,
        element = "repl",
      },
      render = { indent = 1, max_value_lines = 100 },
    })
    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close()
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close()
    end
  end

  -- Re-send breakpoints after session fully initializes.
  -- On cold start, the adapter may not have loaded the binary yet when
  -- the initial setBreakpoints is sent, causing them to be rejected.
  dap.listeners.after.event_initialized["reapply_breakpoints"] = function()
    vim.defer_fn(function()
      local session = dap.session()
      if not session then
        return
      end
      local bps = require("dap.breakpoints").get()
      if vim.tbl_count(bps) > 0 then
        session:set_breakpoints(bps)
      end
    end, 500)
  end

  -- Restore breakpoint signs after session ends.
  dap.listeners.before.event_initialized["save_breakpoints"] = function()
    local snapshot = {}
    for bufnr, bps in pairs(require("dap.breakpoints").get()) do
      local name = vim.api.nvim_buf_get_name(bufnr)
      if name ~= "" then
        snapshot[name] = bps
      end
    end
    rawset(_G, "_dap_saved_breakpoints", snapshot)
  end
  local function restore_breakpoints_if_missing()
    local saved = rawget(_G, "_dap_saved_breakpoints")
    if not saved or vim.tbl_isempty(saved) then
      return
    end
    local bp_mod = require("dap.breakpoints")
    if vim.tbl_count(bp_mod.get()) > 0 then
      return
    end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local name = vim.api.nvim_buf_get_name(buf)
      local bps = saved[name]
      if bps and vim.api.nvim_buf_is_loaded(buf) then
        for _, bp in ipairs(bps) do
          bp_mod.set({
            condition = bp.condition,
            log_message = bp.logMessage,
            hit_condition = bp.hitCondition,
          }, buf, bp.line)
        end
      end
    end
    rawset(_G, "_dap_saved_breakpoints", nil)
  end
  dap.listeners.after.event_terminated["restore_breakpoints"] = function()
    vim.defer_fn(restore_breakpoints_if_missing, 500)
  end
  dap.listeners.after.event_exited["restore_breakpoints"] = function()
    vim.defer_fn(restore_breakpoints_if_missing, 500)
  end

  -- ══════════════════════════════════════════════════════════════════
  -- [4] Virtual Text
  -- ══════════════════════════════════════════════════════════════════
  local ok_vt, vt = pcall(require, "nvim-dap-virtual-text")
  if ok_vt then
    vt.setup({
      enabled = true,
      enable_commands = true,
      highlight_changed_variables = true,
      show_stop_reason = true,
      only_first_definition = true,
      display_callback = function(variable, buf, stackframe, node, options)
        if not buf or not stackframe or not node then
          return nil
        end
        if options.virt_text_pos == "inline" then
          return " = " .. variable.value:gsub("%s+", " ")
        else
          return variable.name .. " = " .. variable.value:gsub("%s+", " ")
        end
      end,
      virt_text_pos = vim.fn.has("nvim-0.10") == 1 and "inline" or "eol",
    })
  end

  -- ══════════════════════════════════════════════════════════════════
  -- [5] Persistent Breakpoints
  -- ══════════════════════════════════════════════════════════════════
  if utils.enabled(pgroup, "persistent_breakpoints") then
    local ok_pb, pb = pcall(require, "persistent-breakpoints")
    if ok_pb then
      pb.setup({
        save_dir = vim.fn.stdpath("data") .. "/breakpoints",
        load_breakpoints_event = { "BufReadPost" },
      })
    end
  end

  -- ══════════════════════════════════════════════════════════════════
  -- [6] Telescope DAP
  -- ══════════════════════════════════════════════════════════════════
  if utils.enabled(pgroup, "telescope") then
    pcall(function()
      require("telescope").load_extension("dap")
    end)
  end
end

local ok_dap = pcall(require, "dap")
if ok_dap then
  setup_dap()
end
