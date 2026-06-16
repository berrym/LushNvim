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
    "akinsho/bufferline.nvim",
    cond = enabled(group, "bufferline"),
    lazy = false,
  },
  {
    "sindrets/diffview.nvim",
    cond = enabled(group, "diffview"),
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewToggleFiles",
      "DiffviewRefresh",
    },
  },
  -- gitsigns: setup lives in after/plugin/gitsigns.lua so :LushReload picks
  -- up config changes (lazy's `config = function` runs exactly once at load).
  {
    "lewis6991/gitsigns.nvim",
    cond = enabled(group, "gitsigns"),
    event = "VimEnter",
  },
  {
    "folke/flash.nvim",
    cond = enabled(group, "flash"),
    event = "VeryLazy",
  },
  {
    "HakonHarnes/img-clip.nvim",
    cond = enabled(group, "img_clip"),
    event = "BufEnter",
  },
  {
    "neovim/nvim-lspconfig",
    cond = enabled(group, "lsp"),
    event = "VimEnter",
  },
  {
    "mason-org/mason.nvim",
    cond = enabled(group, "lsp"),
    event = "VimEnter",
  },
  {
    "mason-org/mason-lspconfig.nvim",
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
  -- JSON schema catalog for jsonls (gated by `web` bundle's enable_plugins).
  {
    "b0o/SchemaStore.nvim",
    cond = enabled(group, "schemastore"),
    lazy = true, -- loaded on demand by jsonls before_init hook
    version = false, -- track main; schemas update frequently
  },
  -- ── JS/TS ecosystem plugins (gated by `typescript` bundle's enable_plugins) ──
  {
    "vuki656/package-info.nvim",
    cond = enabled(group, "package_info"),
    dependencies = { "MunifTanjim/nui.nvim" },
    event = { "BufRead package.json" },
    opts = {
      package_manager = "auto",
      hide_up_to_date = true,
      hide_unstable_versions = false,
    },
  },
  {
    "dmmulroy/ts-error-translator.nvim",
    cond = enabled(group, "ts_error_translator"),
    ft = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" },
    config = true,
  },
  {
    "axelvc/template-string.nvim",
    cond = enabled(group, "template_string"),
    ft = {
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "python",
      "vue",
      "svelte",
    },
    opts = {
      filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "python",
        "vue",
        "svelte",
      },
      jsx_brackets = true,
      remove_template_string = true,
      restore_quotes = { normal = [["]], jsx = [["]] },
    },
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
    "olimorris/persisted.nvim",
    cond = enabled(group, "session_manager"),
    lazy = false,
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
    -- LSP snippets are handled natively via vim.snippet; no extra engine required.
    dependencies = {
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
    -- pin to v1.x to avoid breaking v2 migration (v2 requires blink.lib dependency)
    version = "1.*",
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
      {
        "<leader>dc",
        function()
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
                if config[k] == nil or config[k] == "" then
                  return
                end
              end
            end
            dap.run(config)
          end
        end,
        desc = "Continue / Start",
      },
      {
        "<leader>dn",
        function()
          require("dap").step_over()
        end,
        desc = "Step over",
      },
      {
        "<leader>di",
        function()
          require("dap").step_into()
        end,
        desc = "Step into",
      },
      {
        "<leader>do",
        function()
          require("dap").step_out()
        end,
        desc = "Step out",
      },
      {
        "<leader>dp",
        function()
          require("dap").pause()
        end,
        desc = "Pause",
      },
      {
        "<leader>dC",
        function()
          require("dap").run_to_cursor()
        end,
        desc = "Run to cursor",
      },
      {
        "<leader>dL",
        function()
          require("dap").run_last()
        end,
        desc = "Run last",
      },
      {
        "<leader>dr",
        function()
          require("dap").restart()
        end,
        desc = "Restart",
      },
      {
        "<leader>dt",
        function()
          require("dap").terminate({}, {}, function()
            pcall(function()
              require("dapui").close()
            end)
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
              if vim.tbl_count(bp_mod.get()) > 0 then
                return
              end
              -- Use the saved snapshot (set by before.event_initialized listener)
              local saved = rawget(_G, "_dap_saved_breakpoints")
              if not saved or vim.tbl_isempty(saved) then
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
            end, 2000)
          end)
        end,
        desc = "Terminate",
      },
      {
        "<leader>dq",
        function()
          require("dap").disconnect({ terminateDebuggee = true }, function()
            pcall(function()
              require("dapui").close()
            end)
          end)
        end,
        desc = "Disconnect",
      },
      -- Breakpoints (routed through persistent-breakpoints when available
      -- so they survive DirChanged reloads and persist across nvim restarts)
      {
        "<leader>db",
        function()
          local ok, pb = pcall(require, "persistent-breakpoints.api")
          if ok then
            pb.toggle_breakpoint()
          else
            require("dap").toggle_breakpoint()
          end
        end,
        desc = "Toggle breakpoint",
      },
      {
        "<leader>dB",
        function()
          vim.ui.input({ prompt = "Breakpoint condition: " }, function(cond)
            if cond then
              require("dap").set_breakpoint(cond)
              pcall(function()
                require("persistent-breakpoints.api").breakpoints_changed_in_current_buffer()
              end)
            end
          end)
        end,
        desc = "Conditional breakpoint",
      },
      {
        "<leader>dl",
        function()
          vim.ui.input({ prompt = "Log point message: " }, function(msg)
            if msg then
              require("dap").set_breakpoint(nil, nil, msg)
              pcall(function()
                require("persistent-breakpoints.api").breakpoints_changed_in_current_buffer()
              end)
            end
          end)
        end,
        desc = "Log point",
      },
      {
        "<leader>dx",
        function()
          local ok, pb = pcall(require, "persistent-breakpoints.api")
          if ok then
            pb.clear_all_breakpoints()
          else
            require("dap").clear_breakpoints()
          end
        end,
        desc = "Clear all breakpoints",
      },
      -- UI and inspection
      {
        "<leader>du",
        function()
          require("dapui").toggle()
        end,
        desc = "Toggle DAP UI",
      },
      {
        "<leader>de",
        function()
          require("dapui").eval()
        end,
        desc = "Eval expression",
      },
      {
        "<leader>de",
        function()
          require("dapui").eval()
        end,
        desc = "Eval selection",
        mode = "v",
      },
      {
        "<leader>dh",
        function()
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
        end,
        desc = "Hover variable",
      },
      {
        "<leader>dw",
        function()
          vim.ui.input({ prompt = "Watch expression: " }, function(expr)
            if expr then
              require("dapui").elements.watches.add(expr)
            end
          end)
        end,
        desc = "Add watch",
      },
      {
        "<leader>dR",
        function()
          require("dap").repl.toggle()
        end,
        desc = "Toggle REPL",
      },
      -- Stack navigation
      {
        "<leader>dj",
        function()
          require("dap").down()
        end,
        desc = "Stack frame down",
      },
      {
        "<leader>dk",
        function()
          require("dap").up()
        end,
        desc = "Stack frame up",
      },
      -- Telescope pickers
      { "<leader>ds", "<CMD>Telescope dap frames<CR>", desc = "Stack frames" },
      { "<leader>dv", "<CMD>Telescope dap variables<CR>", desc = "Variables" },
      { "<leader>df", "<CMD>Telescope dap list_breakpoints<CR>", desc = "Find breakpoints" },
      { "<leader>dD", "<CMD>Telescope dap configurations<CR>", desc = "Debug configurations" },
    },
    -- config lives in after/plugin/dap.lua so :LushReload picks up changes.
    -- That file hooks the User LazyLoad event to fire setup when keys-trigger
    -- loading brings nvim-dap up.
  },
  -- nvim-notify: setup lives in after/plugin/notify.lua so :LushReload picks
  -- up config changes (lazy's `config = function` runs exactly once at load).
  {
    "rcarriga/nvim-notify",
    cond = enabled(group, "notify"),
    lazy = false,
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
      { "windwp/nvim-ts-autotag", cond = enabled(group, "autotag") },
      { "HiPhish/rainbow-delimiters.nvim", cond = enabled(group, "rainbow") },
      -- ts-context-commentstring: setup lives in after/plugin/treesitter.lua
      -- alongside the rest of treesitter wiring (reload-friendly).
      { "JoosepAlviste/nvim-ts-context-commentstring" },
    },
  },
  -- nvim-ufo: setup lives in after/plugin/ufo.lua so :LushReload picks up
  -- config changes.
  {
    "kevinhwang91/nvim-ufo",
    cond = enabled(group, "ufo"),
    event = "VimEnter",
    dependencies = "kevinhwang91/promise-async",
  },
  { "nvim-lua/plenary.nvim" },
  {
    "DrKJeff16/project.nvim",
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
    "folke/trouble.nvim",
    cond = enabled(group, "trouble"),
    opts = {},
    cmd = { "Trouble" },
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
    version = "^8",
    cond = enabled(group, "rustaceanvim"),
    lazy = false,
    ft = { "rust" },
  },
  -- snacks.nvim: modern utility plugins collection (additional features, not replacements)
  -- Module opt-in is driven by enable_plugins.snacks_<module> in user/config.lua so
  -- every snacks module follows LushNvim's per-feature enable-flag pattern.
  -- snacks: opts construction lives in lua/lush/snacks_opts.lua. lazy.nvim
  -- runs Snacks.setup() once with these opts at startup. snacks.setup is
  -- one-shot (no re-config API), so toggling enable_plugins.snacks_<module>
  -- requires a restart -- after/plugin/snacks.lua deliberately does NOT
  -- re-invoke setup (doing so errors "snacks.nvim is already setup").
  {
    "folke/snacks.nvim",
    cond = enabled(group, "snacks"),
    priority = 1000,
    lazy = false,
    opts = function()
      return require("lush.snacks_opts").build()
    end,
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
