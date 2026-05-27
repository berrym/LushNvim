local null_ls = require("null-ls")
local utils = require("config.utils")
local user_config = utils.get_user_config()
local sources = user_config.setup_sources and user_config.setup_sources(null_ls.builtins) or {}

-- Format-on-save is governed by M.autocommands.format_on_save (lua/config/
-- autocommands.lua's `format_on_save` block). It calls vim.lsp.buf.format
-- which already iterates all attached clients including null-ls, so a
-- separate on_attach BufWritePre here would just duplicate work — and
-- previously fired unconditionally, ignoring the user's opt-in flag.
null_ls.setup({
  sources = sources,
})
