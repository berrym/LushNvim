-- JavaScript / TypeScript — first-class language support.
-- LSP: vtsls (primary) + eslint-lsp (lint/fix).
-- Formatting: prettierd via null-ls (already wired for js/ts/jsx/tsx filetypes).
-- DAP: vscode-js-debug via `js-debug-adapter` mason package — direct, no wrapper plugin.
-- Keybindings under <leader>j.

local utils = require("config.utils")
local group = utils.get_plugin_group()

local JS_FTS = {
  "javascript",
  "javascriptreact",
  "javascript.jsx",
  "typescript",
  "typescriptreact",
  "typescript.tsx",
}

-- Run a vtsls-registered workspace command. See vtsls README for the full command list.
local function vtsls_exec(command, args, bufnr)
  local client = vim.lsp.get_clients({ name = "vtsls", bufnr = bufnr or 0 })[1]
  if not client then
    utils.notify_warn("vtsls not attached", "TypeScript")
    return
  end
  client:exec_cmd({
    title = command,
    command = command,
    arguments = args or { vim.uri_from_bufnr(bufnr or 0) },
  }, { bufnr = bufnr or 0 })
end

-- Apply a single LSP code-action kind and auto-confirm.
local function code_action(kind)
  vim.lsp.buf.code_action({
    apply = true,
    context = { only = { kind }, diagnostics = {} },
  })
end

if utils.enabled(group, "lsp") then
  -- Disable vtsls formatting provider so prettierd wins (avoids duplicate formatters).
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lush_ts_lsp_attach", { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client then
        return
      end
      if client.name == "vtsls" then
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
      end
    end,
    desc = "JS/TS: let prettierd own formatting instead of vtsls",
  })

  -- Keybindings only bound in JS/TS buffers.
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("lush_ts_keymaps", { clear = true }),
    pattern = JS_FTS,
    callback = function(args)
      local opts = { buffer = args.buf, silent = true }
      local bind = function(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, vim.tbl_extend("force", opts, { desc = desc }))
      end

      -- Imports & fixes (LSP code actions + vtsls commands)
      bind("<leader>ji", function()
        code_action("source.organizeImports")
      end, "Organize imports")
      bind("<leader>jm", function()
        vtsls_exec("typescript.addMissingImports.ts")
      end, "Add missing imports")
      bind("<leader>ju", function()
        vtsls_exec("typescript.removeUnused.ts")
      end, "Remove unused")
      bind("<leader>jF", function()
        vtsls_exec("typescript.fixAll.ts")
      end, "Fix all (TS)")
      bind("<leader>jf", function()
        vim.lsp.buf.format({ async = true })
      end, "Format (prettier)")

      -- ESLint
      bind("<leader>jl", function()
        code_action("source.fixAll.eslint")
      end, "Fix all (ESLint)")

      -- vtsls-only features
      bind("<leader>jg", function()
        vtsls_exec(
          "typescript.goToSourceDefinition",
          { vim.uri_from_bufnr(0), vim.lsp.util.make_position_params(0, "utf-8").position }
        )
      end, "Go to source definition")
      bind("<leader>jR", function()
        vtsls_exec("typescript.findAllFileReferences")
      end, "Find all file references")
      bind("<leader>jX", function()
        vtsls_exec("typescript.restartTsServer")
      end, "Restart TS server")
      bind("<leader>jv", function()
        vtsls_exec("typescript.selectTypeScriptVersion")
      end, "Select TS version")

      -- Toggle inlay hints
      bind("<leader>jh", function()
        vim.lsp.inlay_hint.enable(
          not vim.lsp.inlay_hint.is_enabled({ bufnr = args.buf }),
          { bufnr = args.buf }
        )
      end, "Toggle inlay hints")
    end,
  })
end

-- ════════════════════════════════════════════════════════════════════════════
-- package-info.nvim — inline package.json version info and actions.
-- ════════════════════════════════════════════════════════════════════════════
if utils.enabled(group, "package_info") then
  vim.api.nvim_create_autocmd("BufRead", {
    group = vim.api.nvim_create_augroup("lush_ts_package_info", { clear = true }),
    pattern = "package.json",
    callback = function(args)
      local opts = { buffer = args.buf, silent = true }
      local ok, pi = pcall(require, "package-info")
      if not ok then
        return
      end
      vim.keymap.set(
        "n",
        "<leader>jp",
        pi.show,
        vim.tbl_extend("force", opts, { desc = "Show package versions" })
      )
      vim.keymap.set(
        "n",
        "<leader>jP",
        pi.toggle,
        vim.tbl_extend("force", opts, { desc = "Toggle package versions" })
      )
      vim.keymap.set(
        "n",
        "<leader>jU",
        pi.update,
        vim.tbl_extend("force", opts, { desc = "Update package" })
      )
      vim.keymap.set(
        "n",
        "<leader>jI",
        pi.install,
        vim.tbl_extend("force", opts, { desc = "Install package" })
      )
      vim.keymap.set(
        "n",
        "<leader>jd",
        pi.delete,
        vim.tbl_extend("force", opts, { desc = "Delete package" })
      )
      vim.keymap.set(
        "n",
        "<leader>jc",
        pi.change_version,
        vim.tbl_extend("force", opts, { desc = "Change version" })
      )
    end,
  })
end

-- ════════════════════════════════════════════════════════════════════════════
-- DAP — vscode-js-debug direct. No wrapper plugin (mxsdev/nvim-dap-vscode-js
-- is unmaintained and unnecessary since js-debug v1.77 shipped dapDebugServer.js).
-- ════════════════════════════════════════════════════════════════════════════
if utils.enabled(group, "dap") and utils.enabled(group, "dap_js") then
  local ok_dap, dap = pcall(require, "dap")
  if ok_dap then
    local js_debug = vim.fn.stdpath("data")
      .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"

    local function server_adapter()
      return {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "node",
          args = { js_debug, "${port}" },
        },
      }
    end

    dap.adapters["pwa-node"] = server_adapter()
    dap.adapters["pwa-chrome"] = server_adapter()
    dap.adapters["node-terminal"] = server_adapter()

    -- Share configurations across all JS/TS filetypes.
    local js_configs = {
      {
        type = "pwa-node",
        request = "launch",
        name = "Launch current file (node)",
        cwd = "${workspaceFolder}",
        program = "${file}",
        runtimeExecutable = "node",
        sourceMaps = true,
        resolveSourceMapLocations = { "${workspaceFolder}/**", "!**/node_modules/**" },
      },
      {
        type = "pwa-node",
        request = "launch",
        name = "Launch via tsx (TypeScript)",
        cwd = "${workspaceFolder}",
        runtimeExecutable = "tsx",
        args = { "${file}" },
        sourceMaps = true,
      },
      {
        type = "pwa-node",
        request = "launch",
        name = "Debug Jest (current file)",
        runtimeExecutable = "node",
        runtimeArgs = { "./node_modules/jest/bin/jest.js", "--runInBand", "${file}" },
        cwd = "${workspaceFolder}",
        console = "integratedTerminal",
        internalConsoleOptions = "neverOpen",
      },
      {
        type = "pwa-node",
        request = "launch",
        name = "Debug Vitest (current file)",
        runtimeExecutable = "node",
        runtimeArgs = { "./node_modules/vitest/vitest.mjs", "run", "${file}" },
        cwd = "${workspaceFolder}",
        console = "integratedTerminal",
        internalConsoleOptions = "neverOpen",
      },
      {
        type = "pwa-node",
        request = "attach",
        name = "Attach to running Node process",
        processId = function()
          return require("dap.utils").pick_process()
        end,
        cwd = "${workspaceFolder}",
        sourceMaps = true,
      },
      {
        type = "pwa-chrome",
        request = "launch",
        name = "Launch Chrome against localhost",
        url = "http://localhost:3000",
        webRoot = "${workspaceFolder}",
        sourceMaps = true,
      },
    }

    for _, ft in ipairs({ "javascript", "javascriptreact", "typescript", "typescriptreact" }) do
      dap.configurations[ft] = js_configs
    end

    -- Debug keybindings in JS/TS buffers.
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("lush_ts_dap_keymaps", { clear = true }),
      pattern = JS_FTS,
      callback = function(args)
        local opts = { buffer = args.buf, silent = true }
        local bind = function(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, vim.tbl_extend("force", opts, { desc = desc }))
        end
        bind("<leader>jD", function()
          dap.continue()
        end, "Debug (pick config)")
        bind("<leader>jb", function()
          -- Shortcut to launch Chrome config directly
          dap.run({
            type = "pwa-chrome",
            request = "launch",
            name = "Chrome localhost:3000",
            url = "http://localhost:3000",
            webRoot = "${workspaceFolder}",
            sourceMaps = true,
          })
        end, "Debug browser (Chrome)")
      end,
    })

    -- Sanity warning if mason hasn't installed js-debug yet.
    if vim.fn.filereadable(js_debug) == 0 then
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("lush_ts_dap_missing_warn", { clear = true }),
        pattern = JS_FTS,
        once = true,
        callback = function()
          utils.notify_warn(
            "js-debug-adapter not installed — run :Mason or :LushUpdate",
            "JS/TS DAP"
          )
        end,
      })
    end
  end
end
