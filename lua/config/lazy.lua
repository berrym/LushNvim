local notify_info = require("config.utils").notify_info
local enabled = require("config.utils").enabled
local exist, user_config = pcall(require, "user.config")
local group = exist and type(user_config) == "table" and user_config.enable_plugins or {}
local custom_plugins = exist and type(user_config) == "table" and user_config.plugins or {}

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
  {
    "stevearc/aerial.nvim",
    cond = enabled(group, "aerial"),
    cmd = "AerialToggle",
  },
  {
    "goolord/alpha-nvim",
    cond = enabled(group, "alpha"),
    lazy = false,
  },
  {
    "akinsho/bufferline.nvim",
    cond = enabled(group, "bufferline"),
    lazy = false,
  },
  {
    "sindrets/diffview.nvim",
    cond = enabled(group, "diffview"),
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles", "DiffviewRefresh" },
  },
  {
    "lewis6991/gitsigns.nvim",
    cond = enabled(group, "gitsigns"),
    event = "VimEnter",
    config = function()
      require("gitsigns").setup({
        on_attach = require("config.keybindings").gitsigns(),
      })
    end,
  },
  {
    "smoka7/hop.nvim",
    version = "*",
    cond = enabled(group, "hop"),
    event = "VimEnter",
  },
  {
    "HakonHarnes/img-clip.nvim",
    cond = enabled(group, "img_clip"),
    event = "BufEnter",
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    cond = enabled(group, "indent_blankline"),
    event = "VimEnter",
  },
  {
    "neovim/nvim-lspconfig",
    cond = enabled(group, "lsp"),
    event = "VimEnter",
  },
  {
    "williamboman/mason.nvim",
    cond = enabled(group, "lsp"),
    event = "VimEnter",
  },
  {
    "williamboman/mason-lspconfig.nvim",
    cond = enabled(group, "lsp"),
    event = "VimEnter",
  },
  {
    "folke/lazydev.nvim",
    cond = enabled(group, "lazydev"),
    ft = "lua",
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  {
    "karb94/neoscroll.nvim",
    cond = enabled(group, "neoscroll"),
    event = "VeryLazy",
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    cond = enabled(group, "neotree"),
    event = "VeryLazy",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
      -- "3rd/image.nvim", -- requires luarocks
    },
  },
  {
    "Shatur/neovim-session-manager",
    cond = enabled(group, "session_manager"),
    event = "VimEnter",
  },
  {
    "folke/noice.nvim",
    cond = enabled(group, "noice"),
    event = "VimEnter",
    dependencies = { { "MunifTanjim/nui.nvim" } },
  },
  {
    "nvimtools/none-ls.nvim",
    cond = enabled(group, "null_ls"),
    lazy = false,
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      {
        "jay-babu/mason-null-ls.nvim",
        cmd = { "NullLsInstall", "NullLsUninstall" },
      },
    },
  },
  {
    "windwp/nvim-autopairs",
    cond = enabled(group, "autopairs"),
    event = "InsertEnter",
  },
  {
    "saghen/blink.cmp",
    cond = enabled(group, "cmp"),
    event = "InsertEnter",
    -- optional: provides snippets for the snippet source
    dependencies = {
      { "rafamadriz/friendly-snippets" },
      { "L3MON4D3/LuaSnip",            version = "v2.*" },
      { "echasnovski/mini.snippets" },
      {
        "zbirenbaum/copilot.lua",
        cond = enabled(group, "copilot"),
        cmd = "Copilot",
        event = "InsertEnter",
      },
      {
        "fang2hou/blink-copilot",
        cond = enabled(group, "copilot"),
      },
    },
    -- use a release tag to download pre-built binaries
    version = "*",
    -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    -- build = 'cargo build --release',
    -- If you use nix, you can build from source using latest nightly rust with:
    -- build = 'nix run .#build-plugin',
  },
  { "NvChad/nvim-colorizer.lua", cond = enabled(group, "colorizer"), event = "VimEnter" },
  {
    "mfussenegger/nvim-dap",
    cond = enabled(group, "dap"),
    dependencies = {
      {
        "jay-babu/mason-nvim-dap.nvim",
        cmd = { "DapInstall", "DapUninstall" },
        config = function() end, -- intentionally empty: setup called by nvim-dap's config
      },
      { "rcarriga/nvim-dap-ui" },
      { "theHamsta/nvim-dap-virtual-text" },
      { "nvim-neotest/nvim-nio" },
      { "mfussenegger/nvim-dap-python", ft = "python" },
      { "leoluz/nvim-dap-go", ft = "go" },
      { "nvim-telescope/telescope-dap.nvim" },
      { "Weissle/persistent-breakpoints.nvim" },
    },
    -- keys trigger lazy loading AND define all debug keybindings
    keys = {
      -- Core flow
      { "<leader>dc", function()
        local dap = require("dap")
        if dap.session() then
          dap.continue()
        else
          local configs = dap.configurations[vim.bo.filetype]
          if not configs or #configs == 0 then
            vim.notify("No debug config for " .. vim.bo.filetype, vim.log.levels.WARN)
            return
          end
          -- Deep-copy and pre-resolve function values (program path, args)
          -- BEFORE starting the session. This prevents vim.fn.input() from
          -- running mid-session-init, which clears breakpoint signs on cold start.
          local config = vim.deepcopy(configs[1])
          for k, v in pairs(config) do
            if type(v) == "function" then
              config[k] = v()
              if config[k] == nil or config[k] == "" then return end
            end
          end
          dap.run(config)
        end
      end, desc = "Continue / Start" },
      { "<leader>dn", function() require("dap").step_over() end, desc = "Step over" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>do", function() require("dap").step_out() end, desc = "Step out" },
      { "<leader>dp", function() require("dap").pause() end, desc = "Pause" },
      { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to cursor" },
      { "<leader>dL", function() require("dap").run_last() end, desc = "Run last" },
      { "<leader>dr", function() require("dap").restart() end, desc = "Restart" },
      { "<leader>dt", function()
        require("dap").terminate({}, {}, function()
          pcall(function() require("dapui").close() end)
          -- Close any lingering dap floating windows (hovers/evals)
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            local bt = vim.bo[buf].buftype
            if vim.api.nvim_win_get_config(win).relative ~= "" and bt == "nofile" then
              pcall(vim.api.nvim_win_close, win, true)
            end
          end
          -- Restore modifiable on source buffers
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.bo[buf].buftype == "" and vim.api.nvim_buf_is_loaded(buf) then
              vim.bo[buf].modifiable = true
            end
          end
          -- Fallback: event listeners also restore at 500ms, but this
          -- catches adapters that don't emit terminated/exited events.
          vim.defer_fn(function()
            local bp_mod = require("dap.breakpoints")
            if vim.tbl_count(bp_mod.get()) > 0 then return end
            -- Use the saved snapshot (set by before.event_initialized listener)
            local saved = rawget(_G, "_dap_saved_breakpoints")
            if not saved or vim.tbl_isempty(saved) then return end
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
          end, 2000)
        end)
      end, desc = "Terminate" },
      { "<leader>dq", function()
        require("dap").disconnect({ terminateDebuggee = true }, function()
          pcall(function() require("dapui").close() end)
        end)
      end, desc = "Disconnect" },
      -- Breakpoints (routed through persistent-breakpoints when available
      -- so they survive DirChanged reloads and persist across nvim restarts)
      { "<leader>db", function()
        local ok, pb = pcall(require, "persistent-breakpoints.api")
        if ok then pb.toggle_breakpoint() else require("dap").toggle_breakpoint() end
      end, desc = "Toggle breakpoint" },
      { "<leader>dB", function()
        vim.ui.input({ prompt = "Breakpoint condition: " }, function(cond)
          if cond then
            require("dap").set_breakpoint(cond)
            pcall(function() require("persistent-breakpoints.api").breakpoints_changed_in_current_buffer() end)
          end
        end)
      end, desc = "Conditional breakpoint" },
      { "<leader>dl", function()
        vim.ui.input({ prompt = "Log point message: " }, function(msg)
          if msg then
            require("dap").set_breakpoint(nil, nil, msg)
            pcall(function() require("persistent-breakpoints.api").breakpoints_changed_in_current_buffer() end)
          end
        end)
      end, desc = "Log point" },
      { "<leader>dx", function()
        local ok, pb = pcall(require, "persistent-breakpoints.api")
        if ok then pb.clear_all_breakpoints() else require("dap").clear_breakpoints() end
      end, desc = "Clear all breakpoints" },
      -- UI and inspection
      { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
      { "<leader>de", function() require("dapui").eval() end, desc = "Eval expression" },
      { "<leader>de", function() require("dapui").eval() end, desc = "Eval selection", mode = "v" },
      { "<leader>dh", function()
        -- Toggle: if a hover float is open, close it; otherwise open eval
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_config(win).relative ~= "" then
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].filetype == "dapui_hover" then
              pcall(vim.api.nvim_win_close, win, true)
              return
            end
          end
        end
        -- Open eval, then defer focus into the float (eval is async)
        require("dapui").eval()
        vim.defer_fn(function()
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_config(win).relative ~= "" then
              local buf = vim.api.nvim_win_get_buf(win)
              if vim.bo[buf].filetype == "dapui_hover" then
                vim.api.nvim_set_current_win(win)
                return
              end
            end
          end
        end, 100)
      end, desc = "Hover variable" },
      { "<leader>dw", function()
        vim.ui.input({ prompt = "Watch expression: " }, function(expr)
          if expr then require("dapui").elements.watches.add(expr) end
        end)
      end, desc = "Add watch" },
      { "<leader>dR", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      -- Stack navigation
      { "<leader>dj", function() require("dap").down() end, desc = "Stack frame down" },
      { "<leader>dk", function() require("dap").up() end, desc = "Stack frame up" },
      -- Telescope pickers
      { "<leader>ds", "<CMD>Telescope dap frames<CR>", desc = "Stack frames" },
      { "<leader>dv", "<CMD>Telescope dap variables<CR>", desc = "Variables" },
      { "<leader>df", "<CMD>Telescope dap list_breakpoints<CR>", desc = "Find breakpoints" },
      { "<leader>dD", "<CMD>Telescope dap configurations<CR>", desc = "Debug configurations" },
    },
    config = function()
      local dap = require("dap")
      local utils = require("config.utils")
      local pgroup = utils.get_plugin_group()

      -- ══════════════════════════════════════════════════════════════════
      -- [1] mason-nvim-dap: auto-configure ALL installed debug adapters
      -- Ensure mason.setup() has run first so its bin/ is on PATH
      -- (nvim-dap config may fire before lsp.lua's mason.setup call)
      -- ══════════════════════════════════════════════════════════════════
      pcall(function() require("mason").setup() end)

      local ok_mason_dap, mason_dap = pcall(require, "mason-nvim-dap")
      if ok_mason_dap then
        local user_config = utils.get_user_config()
        local sources = user_config.mason_ensure_installed
            and user_config.mason_ensure_installed.dap or {}
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
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_dap_highlights })

      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint", numhl = "DapBreakpoint" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◉", texthl = "DapBreakpointCondition", numhl = "DapBreakpointCondition" })
      vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DapLogPoint", numhl = "DapLogPoint" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DapStopped", linehl = "DapStoppedLine", numhl = "DapStopped" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DapBreakpointRejected", numhl = "DapBreakpointRejected" })

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
        dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
        dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
        dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
      end

      -- Re-send breakpoints after session fully initializes.
      -- On cold start, the adapter may not have loaded the binary yet when
      -- the initial setBreakpoints is sent, causing them to be rejected.
      dap.listeners.after.event_initialized["reapply_breakpoints"] = function()
        vim.defer_fn(function()
          local session = dap.session()
          if not session then return end
          local bps = require("dap.breakpoints").get()
          if vim.tbl_count(bps) > 0 then
            session:set_breakpoints(bps)
          end
        end, 500)
      end

      -- Restore breakpoint signs after session ends.
      -- CWD can change during debug (NeoTree, project detection), so we
      -- snapshot breakpoints by file path before the session starts and
      -- restore from the snapshot if signs are lost during teardown.
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
        if not saved or vim.tbl_isempty(saved) then return end
        local bp_mod = require("dap.breakpoints")
        if vim.tbl_count(bp_mod.get()) > 0 then return end
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
            if not buf or not stackframe or not node then return nil end
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
        pcall(function() require("telescope").load_extension("dap") end)
      end
    end,
  },
  {
    "rcarriga/nvim-notify",
    cond = enabled(group, "notify"),
    lazy = false,
    config = function()
      vim.notify = require("notify")
      _G.message = require("notify")
    end,
  },
  {
    "kylechui/nvim-surround",
    cond = enabled(group, "surround"),
    event = "VimEnter",
    opts = {},
  },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    cond = enabled(group, "treesitter"),
    lazy = false,
    build = ":TSUpdate",
    dependencies = {
      { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
      {
        "nvim-treesitter/nvim-treesitter-context",
        cond = enabled(group, "context"),
      },
      { "windwp/nvim-ts-autotag",                     cond = enabled(group, "autotag") },
      { "HiPhish/rainbow-delimiters.nvim",            cond = enabled(group, "rainbow") },
      {
        "JoosepAlviste/nvim-ts-context-commentstring",
        config = function()
          require("ts_context_commentstring").setup({
            enable_autocmd = false,
          })
        end,
      },
    },
  },
  {
    "kevinhwang91/nvim-ufo",
    cond = enabled(group, "ufo"),
    event = "VimEnter",
    dependencies = "kevinhwang91/promise-async",
    config = function()
      require("ufo").setup()
    end,
  },
  {
    "AstroNvim/astrotheme",
    cond = enabled(group, "astrotheme"),
    lazy = false,
  },
  { "nvim-lua/plenary.nvim" },
  {
    "ahmedkhalf/project.nvim",
    cond = enabled(group, "project"),
    event = "VimEnter",
  },
  {
    "tiagovla/scope.nvim",
    cond = enabled(group, "scope"),
    event = "VimEnter",
  },
  {
    "nvim-telescope/telescope.nvim",
    cond = enabled(group, "telescope"),
    cmd = "Telescope",
    dependencies = {
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
      {
        "nvim-telescope/telescope-ui-select.nvim",
      },
    },
  },
  {
    "akinsho/toggleterm.nvim",
    cond = enabled(group, "toggleterm"),
    event = "VeryLazy",
  },
  {
    "folke/trouble.nvim",
    cond = enabled(group, "trouble"),
    opts = {},
    cmd = { "Trouble" },
  },
  {
    "folke/twilight.nvim",
    cond = enabled(group, "twilight"),
    cmd = { "Twilight", "TwilightEnable", "TwilightDisable" },
  },
  {
    "folke/which-key.nvim",
    cond = enabled(group, "whichkey"),
    event = "VeryLazy",
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
  {
    "folke/zen-mode.nvim",
    cond = enabled(group, "zen"),
    cmd = "ZenMode",
  },
  -- claudecode.nvim: Claude Code CLI integration
  {
    "coder/claudecode.nvim",
    cond = enabled(group, "claudecode"),
    event = "VeryLazy",
  },
  -- rustaceanvim: Modern Rust development (successor to rust-tools.nvim)
  -- NOTE: Use `rustup component add rust-analyzer` instead of Mason for rust-analyzer
  {
    "mrcjkb/rustaceanvim",
    version = "^7",
    cond = enabled(group, "rustaceanvim"),
    lazy = false,
    ft = { "rust" },
  },
  -- snacks.nvim: modern utility plugins collection (additional features, not replacements)
  {
    "folke/snacks.nvim",
    cond = enabled(group, "snacks"),
    priority = 1000,
    lazy = false,
    opts = {
      bigfile = { enabled = true },
      quickfile = { enabled = true },
      input = { enabled = true },
      words = { enabled = true },
      bufdelete = { enabled = true },
      debug = { enabled = true },
      git = { enabled = true },
      gitbrowse = { enabled = true },
      rename = { enabled = true },
      toggle = { enabled = true },
      win = { enabled = true },
    },
  },
  custom_plugins,
}

require("lazy").setup(plugins, {
  defaults = { lazy = true },
  change_detection = {
    enabled = true, -- Automatically check for config file changes
    notify = true, -- Show notification when changes detected
  },
  performance = {
    rtp = {
      disabled_plugins = { "tohtml", "gzip", "zipPlugin", "tarPlugin" },
    },
  },
})
