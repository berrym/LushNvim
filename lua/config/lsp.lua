local exist, user_config = pcall(require, "user.config")
local group = exist and type(user_config) == "table" and user_config.enable_plugins or {}
local enabled = require("config.utils").enabled

if enabled(group, "lsp") then
  require("mason").setup()
  require("mason-lspconfig").setup({
    handlers = {
      function(server_name)
        exist, user_config = pcall(require, "user.config")
        local configs = exist and type(user_config) == "table" and user_config.lsp_configs or {}
        local config = type(configs) == "table" and configs[server_name] or {}
        local capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)
        -- Merge user config with capabilities
        local lsp_config = vim.tbl_deep_extend("force", config, {
          capabilities = capabilities,
        })
        vim.lsp.config(server_name, lsp_config)
        vim.lsp.enable(server_name)
      end,
    },
  })

  vim.api.nvim_create_autocmd("LspAttach", {
    desc = "LSP actions",
    callback = function(event)
      local opts = { buffer = event.buf }
      -- g-prefix bindings (traditional)
      vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
      vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
      vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
      vim.keymap.set("n", "go", vim.lsp.buf.type_definition, opts)
      vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
      vim.keymap.set("n", "gR", "<cmd>Telescope lsp_references<cr>", opts)
      vim.keymap.set("n", "gs", vim.lsp.buf.signature_help, opts)
      -- Function key bindings
      vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, opts)
      vim.keymap.set({ "n", "x" }, "<F3>", function() vim.lsp.buf.format({ async = true }) end, opts)
      vim.keymap.set("n", "<F4>", vim.lsp.buf.code_action, opts)
      -- Leader Code bindings (<leader>c)
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = event.buf, desc = "Code action" })
      vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, { buffer = event.buf, desc = "Rename symbol" })
      vim.keymap.set("n", "<leader>cd", vim.lsp.buf.definition, { buffer = event.buf, desc = "Go to definition" })
      vim.keymap.set("n", "<leader>cD", vim.lsp.buf.declaration, { buffer = event.buf, desc = "Go to declaration" })
      vim.keymap.set("n", "<leader>ci", vim.lsp.buf.implementation, { buffer = event.buf, desc = "Go to implementation" })
      vim.keymap.set("n", "<leader>cR", "<cmd>Telescope lsp_references<cr>", { buffer = event.buf, desc = "Find references" })
      vim.keymap.set({ "n", "x" }, "<leader>cf", function() vim.lsp.buf.format({ async = true }) end, { buffer = event.buf, desc = "Format" })
      vim.keymap.set("n", "<leader>ch", vim.lsp.buf.signature_help, { buffer = event.buf, desc = "Signature help" })
    end,
  })

  vim.diagnostic.config({
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = "✘",
        [vim.diagnostic.severity.WARN] = "▲",
        [vim.diagnostic.severity.HINT] = "⚑",
        [vim.diagnostic.severity.INFO] = "»",
      },
    },
  })
end

exist, user_config = pcall(require, "user.config")
group = exist and type(user_config) == "table" and user_config.enable_plugins or {}

if enabled(group, "cmp") then
  require("blink.cmp").setup({
    -- 'default' for mappings similar to built-in completion
    -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
    -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
    -- See the full "keymap" documentation for information on defining your own keymap.
    keymap = {
      -- set to 'none' to disable the 'default' preset
      preset = "enter",
    },
    appearance = {
      -- Sets the fallback highlight groups to nvim-cmp's highlight groups
      -- Useful for when your theme doesn't support blink.cmp
      -- Will be removed in a future release
      use_nvim_cmp_as_default = true,
      -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = "mono",
    },
    completion = {
      list = { selection = { preselect = true, auto_insert = true } },
      ghost_text = {
        enabled = true,
        -- Show the ghost text when an item has been selected
        show_with_selection = true,
        -- Show the ghost text when no item has been selected, defaulting to the first item
        show_without_selection = false,
      },
    },
    cmdline = {
      enabled = false,
    },
  })
end
