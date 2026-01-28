local utils = require("config.utils")
local group = utils.get_plugin_group()
local user_config = utils.get_user_config()
local parsers = user_config.treesitter_ensure_installed or {}

if utils.enabled(group, "treesitter") then
  -- New main branch setup
  require("nvim-treesitter").setup({})

  -- Install parsers
  if #parsers > 0 then
    vim.schedule(function()
      require("nvim-treesitter").install(parsers)
    end)
  end

  -- Enable highlighting globally via autocommand
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("TreesitterHighlight", { clear = true }),
    callback = function(args)
      local ft = vim.bo[args.buf].filetype
      if ft == "" or ft == "alpha" then return end
      local lang = vim.treesitter.language.get_lang(ft)
      if lang and pcall(vim.treesitter.language.inspect, lang) then
        vim.treesitter.start(args.buf, lang)
      end
    end,
  })

  -- Textobjects setup (new main branch API)
  local ok, textobjects = pcall(require, "nvim-treesitter-textobjects")
  if ok then
    textobjects.setup({
      select = {
        lookahead = true,
        keymaps = {
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
          ["aa"] = "@parameter.outer",
          ["ia"] = "@parameter.inner",
        },
      },
      move = {
        set_jumps = true,
        goto_next_start = {
          ["]m"] = "@function.outer",
          ["]]"] = "@class.outer",
        },
        goto_next_end = {
          ["]M"] = "@function.outer",
          ["]["] = "@class.outer",
        },
        goto_previous_start = {
          ["[m"] = "@function.outer",
          ["[["] = "@class.outer",
        },
        goto_previous_end = {
          ["[M"] = "@function.outer",
          ["[]"] = "@class.outer",
        },
      },
    })
  end
end

-- nvim-ts-autotag (independent setup)
if utils.enabled(group, "autotag") then
  require("nvim-ts-autotag").setup({
    opts = {
      enable_close = true,
      enable_rename = true,
      enable_close_on_slash = false,
    },
  })
end

-- rainbow-delimiters (independent setup)
if utils.enabled(group, "rainbow") then
  local rainbow = require("rainbow-delimiters")
  vim.g.rainbow_delimiters = {
    strategy = {
      [""] = rainbow.strategy["global"],
    },
    query = {
      [""] = "rainbow-delimiters",
      lua = "rainbow-blocks",
    },
    blacklist = { "html" },
  }
end
