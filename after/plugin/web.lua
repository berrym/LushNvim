-- Web stack LSP ergonomics (HTML / CSS / SCSS / LESS / JSON / JSONC).
-- vtsls / typescript.lua owns JS/TS; this file is for the static web stack
-- installed by the `web` language bundle. Formatting flows through prettierd
-- (html / cssls / jsonls formatters are disabled in languages.lua so there's
-- a single formatter per filetype).

local utils = require("config.utils")
local group = utils.get_plugin_group()

local WEB_FTS = {
  "html",
  "htmldjango",
  "templ",
  "css",
  "scss",
  "less",
  "sass",
  "json",
  "jsonc",
  "vue",
  "svelte",
}

if utils.enabled(group, "lsp") then
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("lush_web_keymaps", { clear = true }),
    pattern = WEB_FTS,
    callback = function(args)
      local opts = { buffer = args.buf, silent = true }
      local bind = function(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, vim.tbl_extend("force", opts, { desc = desc }))
      end

      bind("<leader>Wf", function()
        vim.lsp.buf.format({ async = true })
      end, "Format (prettier)")
      bind("<leader>Wh", function()
        vim.lsp.inlay_hint.enable(
          not vim.lsp.inlay_hint.is_enabled({ bufnr = args.buf }),
          { bufnr = args.buf }
        )
      end, "Toggle inlay hints")
      bind("<leader>Wa", function()
        vim.lsp.buf.code_action({ apply = true })
      end, "Code action")
    end,
  })

  -- JSON-specific: show the schema auto-attached by jsonls + schemastore for
  -- the current buffer. Useful for verifying that a file like tsconfig.json
  -- or package.json actually picked up its schema.
  if utils.enabled(group, "schemastore") then
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("lush_web_json_schema_info", { clear = true }),
      pattern = { "json", "jsonc" },
      callback = function(args)
        vim.keymap.set("n", "<leader>Wj", function()
          local clients = vim.lsp.get_clients({ name = "jsonls", bufnr = args.buf })
          local jsonls = clients[1]
          if not jsonls then
            utils.notify_warn("jsonls not attached", "Web")
            return
          end
          local schemas = vim.tbl_get(jsonls.settings or {}, "json", "schemas") or {}
          local fname = vim.api.nvim_buf_get_name(args.buf)
          local matches = {}
          for _, s in ipairs(schemas) do
            for _, pat in ipairs(s.fileMatch or {}) do
              if vim.fn.match(fname, vim.fn.glob2regpat(pat)) ~= -1 then
                table.insert(matches, s.name or s.url or pat)
                break
              end
            end
          end
          if #matches == 0 then
            utils.notify_info("No schema matched for this file", "JSON Schema")
          else
            utils.notify_info(table.concat(matches, "\n"), "JSON Schema")
          end
        end, { buffer = args.buf, silent = true, desc = "Show matched JSON schema" })
      end,
    })
  end
end
