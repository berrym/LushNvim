local exist, user_config = pcall(require, "user.config")
local group = exist and type(user_config) == "table" and user_config.enable_plugins or {}
local enabled = require("config.utils").enabled

if enabled(group, "lsp") then
  -- Get user LSP configs and merge blink.cmp capabilities
  local configs = exist and type(user_config) == "table" and user_config.lsp_configs or {}

  -- Wildcard config: apply blink.cmp capabilities to ALL servers as a baseline
  local ok_blink, blink = pcall(require, "blink.cmp")
  local base_capabilities = ok_blink and blink.get_lsp_capabilities() or {}
  vim.lsp.config("*", { capabilities = base_capabilities })

  -- Apply per-server user configs (with blink.cmp capabilities merged)
  if type(configs) == "table" then
    for server_name, config in pairs(configs) do
      local capabilities = ok_blink and blink.get_lsp_capabilities(config.capabilities)
        or config.capabilities
        or {}
      local lsp_config = vim.tbl_deep_extend("force", config, { capabilities = capabilities })
      vim.lsp.config(server_name, lsp_config)
    end
  end

  -- Mason setup (must come after vim.lsp.config calls)
  require("mason").setup()
  require("mason-lspconfig").setup({
    -- automatic_enable = true is the default in v2; servers installed via Mason
    -- are automatically enabled via vim.lsp.enable() using configs registered above
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
      vim.keymap.set({ "n", "x" }, "<F3>", function()
        vim.lsp.buf.format({ async = true })
      end, opts)
      vim.keymap.set("n", "<F4>", vim.lsp.buf.code_action, opts)
      -- Leader Code bindings (<leader>c)
      vim.keymap.set(
        "n",
        "<leader>ca",
        vim.lsp.buf.code_action,
        { buffer = event.buf, desc = "Code action" }
      )
      vim.keymap.set(
        "n",
        "<leader>cr",
        vim.lsp.buf.rename,
        { buffer = event.buf, desc = "Rename symbol" }
      )
      vim.keymap.set(
        "n",
        "<leader>cd",
        vim.lsp.buf.definition,
        { buffer = event.buf, desc = "Go to definition" }
      )
      vim.keymap.set(
        "n",
        "<leader>cD",
        vim.lsp.buf.declaration,
        { buffer = event.buf, desc = "Go to declaration" }
      )
      vim.keymap.set(
        "n",
        "<leader>ci",
        vim.lsp.buf.implementation,
        { buffer = event.buf, desc = "Go to implementation" }
      )
      vim.keymap.set(
        "n",
        "<leader>cR",
        "<cmd>Telescope lsp_references<cr>",
        { buffer = event.buf, desc = "Find references" }
      )
      vim.keymap.set({ "n", "x" }, "<leader>cf", function()
        vim.lsp.buf.format({ async = true })
      end, { buffer = event.buf, desc = "Format" })
      vim.keymap.set(
        "n",
        "<leader>ch",
        vim.lsp.buf.signature_help,
        { buffer = event.buf, desc = "Signature help" }
      )
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
    float = { border = "rounded" },
  })

  -- Neovim <= 0.12.x: the diagnostic underline handler throws "Index out of
  -- bounds" from BufReadPost when a buffer is reloaded shorter than a
  -- diagnostic it still holds — typically a file rewritten by a code agent
  -- and then reopened from the file tree. Fixed on master by
  -- neovim/neovim#40839 (Jul 2026), not backported to 0.12. Until a fixed
  -- build is in use, drop out-of-range diagnostics before they reach the
  -- stock handler. Mirrors the upstream fix: when the buffer isn't loaded
  -- yet the check has to wait for BufRead, since the reload is what changes
  -- the line count. Marked so :LushReload doesn't wrap it twice.
  local stock = vim.diagnostic.handlers.underline
  if stock and not stock._lush_guarded then
    local guarded = { _lush_guarded = true }
    local pending = {} -- namespace -> autocmd id waiting for BufRead

    local function clear_pending(namespace)
      if pending[namespace] then
        pcall(vim.api.nvim_del_autocmd, pending[namespace])
        pending[namespace] = nil
      end
    end

    function guarded.show(namespace, bufnr, diagnostics, opts)
      clear_pending(namespace)
      if not vim.api.nvim_buf_is_loaded(bufnr) then
        pending[namespace] = vim.api.nvim_create_autocmd("BufRead", {
          buffer = bufnr,
          once = true,
          callback = function()
            pending[namespace] = nil
            guarded.show(namespace, bufnr, diagnostics, opts)
          end,
        })
        return
      end
      local line_count = vim.api.nvim_buf_line_count(bufnr)
      local in_range = vim.tbl_filter(function(d)
        return d.lnum < line_count
      end, diagnostics)
      return stock.show(namespace, bufnr, in_range, opts)
    end

    function guarded.hide(namespace, bufnr)
      clear_pending(namespace)
      return stock.hide(namespace, bufnr)
    end

    vim.diagnostic.handlers.underline = guarded
  end
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
    sources = {
      -- "snippets" intentionally absent: no snippet engine is loaded.
      -- LSP-provided snippets (rust-analyzer, gopls, etc.) flow through
      -- the "lsp" source and expand via vim.snippet natively.
      default = { "lsp", "path", "buffer", "copilot" },
      providers = {
        copilot = {
          name = "copilot",
          module = "blink-copilot",
          score_offset = 100,
          async = true,
        },
      },
    },
    cmdline = {
      enabled = false,
    },
  })
end
