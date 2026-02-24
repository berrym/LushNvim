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

  -- Textobjects setup (main branch API - keymaps via vim.keymap.set with module functions)
  local select_ok, ts_select = pcall(require, "nvim-treesitter-textobjects.select")
  local move_ok, ts_move = pcall(require, "nvim-treesitter-textobjects.move")

  if select_ok then
    ts_select.setup({ lookahead = true })

    -- Select: af/if (function), ac/ic (class), aa/ia (parameter)
    vim.keymap.set({ "x", "o" }, "af", function() ts_select.select_textobject("@function.outer", "textobjects") end, { desc = "Select outer function" })
    vim.keymap.set({ "x", "o" }, "if", function() ts_select.select_textobject("@function.inner", "textobjects") end, { desc = "Select inner function" })
    vim.keymap.set({ "x", "o" }, "ac", function() ts_select.select_textobject("@class.outer", "textobjects") end, { desc = "Select outer class" })
    vim.keymap.set({ "x", "o" }, "ic", function() ts_select.select_textobject("@class.inner", "textobjects") end, { desc = "Select inner class" })
    vim.keymap.set({ "x", "o" }, "aa", function() ts_select.select_textobject("@parameter.outer", "textobjects") end, { desc = "Select outer parameter" })
    vim.keymap.set({ "x", "o" }, "ia", function() ts_select.select_textobject("@parameter.inner", "textobjects") end, { desc = "Select inner parameter" })
  end

  if move_ok then
    ts_move.setup({ set_jumps = true })

    -- Move: ]m/[m (function start), ]M/[M (function end), ]]/[[ (class start), ][/[] (class end)
    vim.keymap.set({ "n", "x", "o" }, "]m", function() ts_move.goto_next_start("@function.outer", "textobjects") end, { desc = "Next function start" })
    vim.keymap.set({ "n", "x", "o" }, "]M", function() ts_move.goto_next_end("@function.outer", "textobjects") end, { desc = "Next function end" })
    vim.keymap.set({ "n", "x", "o" }, "]]", function() ts_move.goto_next_start("@class.outer", "textobjects") end, { desc = "Next class start" })
    vim.keymap.set({ "n", "x", "o" }, "][", function() ts_move.goto_next_end("@class.outer", "textobjects") end, { desc = "Next class end" })
    vim.keymap.set({ "n", "x", "o" }, "[m", function() ts_move.goto_previous_start("@function.outer", "textobjects") end, { desc = "Previous function start" })
    vim.keymap.set({ "n", "x", "o" }, "[M", function() ts_move.goto_previous_end("@function.outer", "textobjects") end, { desc = "Previous function end" })
    vim.keymap.set({ "n", "x", "o" }, "[[", function() ts_move.goto_previous_start("@class.outer", "textobjects") end, { desc = "Previous class start" })
    vim.keymap.set({ "n", "x", "o" }, "[]", function() ts_move.goto_previous_end("@class.outer", "textobjects") end, { desc = "Previous class end" })
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
