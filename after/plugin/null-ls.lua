local null_ls = require("null-ls")

local exist, user_config = pcall(require, "user.config")
local sources = exist
    and type(user_config) == "table"
    and user_config.setup_sources
    and user_config.setup_sources(null_ls.builtins)
    or {}

null_ls.setup({
  on_attach = function(client, bufnr)
    if client:supports_method("textDocument/formatting") then
      local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
      vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format({ async = false, timeout = 10000 })
        end,
      })
    end
  end,
  sources = sources,
})
