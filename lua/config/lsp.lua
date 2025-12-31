local exist, custom_config = pcall(require, "custom.custom_config")
local group = exist and type(custom_config) == "table" and custom_config.enable_plugins or {}
local enabled = require("config.utils").enabled

if enabled(group, "lsp") then
  require("mason").setup()
  require("mason-lspconfig").setup({
    handlers = {
      function(server_name)
        -- local capabilities = require("cmp_nvim_lsp").default_capabilities()
        exist, custom_config = pcall(require, "custom.custom_config")
        local configs = exist and type(custom_config) == "table" and custom_config.lsp_configs or {}
        local config = type(configs) == "table" and configs[server_name] or {}
        local capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)
        -- require("lspconfig")[server_name].setup({
        vim.lsp.config(server_name, {
          capabilities = capabilities,
          config = config,
        })
        vim.lsp.enable(server_name)
      end,
    },
  })

  vim.api.nvim_create_autocmd("LspAttach", {
    desc = "LSP actions",
    callback = function(event)
      local opts = { buffer = event.buf }
      vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>", opts)
      vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", opts)
      vim.keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", opts)
      vim.keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<cr>", opts)
      vim.keymap.set("n", "go", "<cmd>lua vim.lsp.buf.type_definition()<cr>", opts)
      vim.keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<cr>", opts)
      vim.keymap.set("n", "gR", "<cmd>Telescope lsp_references<cr>", opts)
      vim.keymap.set("n", "gs", "<cmd>lua vim.lsp.buf.signature_help()<cr>", opts)
      vim.keymap.set("n", "<F2>", "<cmd>lua vim.lsp.buf.rename()<cr>", opts)
      vim.keymap.set({ "n", "x" }, "<F3>", "<cmd>lua vim.lsp.buf.format({async = true})<cr>", opts)
      vim.keymap.set("n", "<F4>", "<cmd>lua vim.lsp.buf.code_action()<cr>", opts)
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

exist, custom_config = pcall(require, "custom.custom_config")
group = exist and type(custom_config) == "table" and custom_config.enable_plugins or {}

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

-- local cmp = require("cmp")
-- local lspkind = require("lspkind")
--
-- require("luasnip.loaders.from_vscode").lazy_load()
--
-- cmp.setup({
--   sources = {
--     { name = "nvim_lsp" },
--     { name = "nvim_lua" },
--     { name = "luasnip" },
--     { name = "buffer" },
--     { name = "path" },
--   },
--   preselect = "item",
--   completion = {
--     completeopt = "menu,menuone,noinsert",
--   },
--   mapping = cmp.mapping.preset.insert({
--     ["<CR>"] = cmp.mapping.confirm({ select = false }),
--     -- Super tab
--     ["<Tab>"] = cmp.mapping(function(fallback)
--       local luasnip = require("luasnip")
--       local col = vim.fn.col(".") - 1
--       if cmp.visible() then
--         cmp.select_next_item({ behavior = "select" })
--       elseif luasnip.expand_or_locally_jumpable() then
--         luasnip.expand_or_jump()
--       elseif col == 0 or vim.fn.getline("."):sub(col, col):match("%s") then
--         fallback()
--       else
--         cmp.complete()
--       end
--     end, { "i", "s" }),
--     -- Super shift tab
--     ["<S-Tab>"] = cmp.mapping(function(fallback)
--       local luasnip = require("luasnip")
--       if cmp.visible() then
--         cmp.select_prev_item({ behavior = "select" })
--       elseif luasnip.locally_jumpable(-1) then
--         luasnip.jump(-1)
--       else
--         fallback()
--       end
--     end, { "i", "s" }),
--     -- Jump to the next snippet placeholder
--     ["<C-f>"] = cmp.mapping(function(fallback)
--       local luasnip = require("luasnip")
--       if luasnip.locally_jumpable(1) then
--         luasnip.jump(1)
--       else
--         fallback()
--       end
--     end, { "i", "s" }),
--     -- Jump to the previous snippet placeholder
--     ["<C-b>"] = cmp.mapping(function(fallback)
--       local luasnip = require("luasnip")
--       if luasnip.locally_jumpable(-1) then
--         luasnip.jump(-1)
--       else
--         fallback()
--       end
--     end, { "i", "s" }),
--   }),
--   window = {
--     completion = cmp.config.window.bordered(),
--     documentation = cmp.config.window.bordered(),
--   },
--   formatting = {
--     format = lspkind.cmp_format({
--       mode = "symbol", -- show only symbol annotations
--       maxwidth = {
--         -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
--         -- can also be a function to dynamically calculate max width such as
--         -- menu = function() return math.floor(0.45 * vim.o.columns) end,
--         menu = 50, -- leading text (labelDetails)
--         abbr = 50, -- actual suggestion item
--       },
--       ellipsis_char = "...", -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
--       show_labelDetails = true, -- show labelDetails in menu. Disabled by default
--
--       -- The function below will be called before any actual modifications from lspkind
--       -- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
--       before = function(_, vim_item)
--         -- ...
--         return vim_item
--       end,
--     }),
--   },
-- })
