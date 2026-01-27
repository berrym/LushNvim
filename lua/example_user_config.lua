-- config.lua is the lua file where user configuration for LushNvim happens
-- This file is a template that covers the most important aspects of configuring LushNvim
-- create a directory named user under the lua folder and copy this file to
-- lua/user/config.lua

local utils = require("config.utils")

local M = {}

-- options put here will override or add on to the default options
M.options = {
  opt = {
    autochdir = false, -- deprecated (don't set), breaks with some plugins, config.autocommands fixes this
    breakindent = true,
    breakindentopt = "shift:2,min:40,sbr",
    clipboard = "unnamedplus",
    colorcolumn = "100",
    confirm = true,
    cursorline = true,
    cursorlineopt = "number",
    expandtab = false,
    foldenable = true,
    foldmethod = "expr",
    foldexpr = "v:lua.vim.treesitter.foldexpr()",
    foldlevel = 99,
    foldlevelstart = 99,
    foldopen = "jump,block,hor,mark,percent,quickfix,search,tag,undo",
    guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20",
    mouse = "a",
    hidden = true,
    hlsearch = true,
    ignorecase = true,
    incsearch = true,
    laststatus = 3,
    -- linebreak = true,
    number = true,
    numberwidth = 6,
    softtabstop = 8,
    shiftwidth = 8,
    relativenumber = true,
    scrolloff = 8,
    sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions",
    sidescrolloff = 8,
    -- showbreak = "=>>",
    showmode = false,
    signcolumn = "yes",
    smartcase = true,
    swapfile = false,
    tabstop = 8,
    textwidth = 100,
    termguicolors = true,
    undofile = true,
    wrap = false,
    writebackup = false,
  },
}

-- add any null-ls sources you want here (uncomment what you want or add your own)
-- function paramater 'b' is shorthand for builtins.
M.setup_sources = function(b)
  return {
    -- b.completion.luasnip,
    -- b.completion.tags,
    -- b.formatting.clang_format,
    -- b.formatting.stylua,
    -- b.formatting.cbfmt,
    -- b.formatting.shfmt,
    -- b.formatting.gofumpt,
    -- b.formatting.goimports_reviser,
    -- b.formatting.black,
    -- b.formatting.prettierd.with({
    --   filetypes = {
    --     "javascript",
    --     "javascriptreact",
    --     "typescript",
    --     "typescriptreact",
    --     "html",
    --     "css",
    --   },
    -- }),
    -- b.formatting.cmake_format,
    -- b.diagnostics.checkmake,
    -- b.diagnostics.pylint,
    -- b.diagnostics.revive,
    -- b.diagnostics.cmake_lint,
    -- b.code_actions.gitrebase,
    -- b.code_actions.gitsigns,
    -- b.code_actions.gomodifytags,
    -- b.code_actions.refactoring,
    -- b.hover.dictionary,
  }
end

-- add mason sources to auto-install (uncomment what you want or add your own)
M.mason_ensure_installed = {
  null_ls = {
    --   "autotools-language-server",
    --   "basedpyright",
    --   "black",
    --   "checkmake",
    --   "clang-format",
    --   "clangd",
    --   "codelldb",
    --   "css-lsp",
    --   "gofumpt",
    --   "goimports-reviser",
    --   "gomodifytags",
    --   "gopls",
    --   "html-lsp",
    --   "json-lsp",
    "lua-language-server",
    --   "mesonlsp",
    --   "prettierd",
    --   "pylint",
    --   "revive",
    --   "ruby-lsp",
    --   "rubyfmt",
    --   "rust-analyzer",
    --   "shfmt",
    "stylua",
    --   "typescript-language-server",
    -- },
    -- dap = {
    --   "python",
  },
}

-- add servers to be used for auto formatting here (uncomment what you want or add your own)
M.formatting_servers = {
  ["null_ls"] = {
    -- "bash",
    -- "c",
    -- "cmake",
    -- "cpp",
    -- "css",
    -- "cuda",
    -- "go",
    -- "html",
    -- "javascript",
    -- "javascriptreact",
    -- "json",
    "lua",
    -- "markdown",
    -- "meson",
    -- "objc",
    -- "objcpp",
    -- "proto",
    -- "python",
    -- "ruby",
    -- "rust",
    -- "sh",
    -- "typescript",
    -- "typescriptreact",
    -- "zsh",
  },
}

-- add treesitter parsers (uncomment what you want or add your own, these don't hurt to install)
M.treesitter_ensure_installed = {
  -- "asm",
  -- "bash",
  -- "c",
  -- "cmake",
  -- "comment",
  -- "cpp",
  -- "css",
  -- "csv",
  -- "cuda",
  -- "diff",
  -- "disassembly",
  -- "dockerfile",
  -- "xml",
  -- "gitattributes",
  -- "gitcommit",
  -- "gitignore",
  -- "glsl",
  -- "go",
  -- "gomod",
  -- "gosum",
  -- "haskell",
  -- "html",
  -- "hyprlang",
  -- "java",
  -- "javascript",
  -- "jsdoc",
  -- "json",
  -- "json5",
  -- "jsonc",
  -- "latex",
  "lua",
  "luap",
  "luau",
  -- "make",
  -- "markdown",
  -- "meson",
  -- "ninja",
  -- "objdump",
  -- "printf",
  -- "python",
  -- "regex",
  -- "ron",
  -- "ruby",
  -- "rust",
  -- "scss",
  -- "toml",
  -- "tsx",
  -- "verilog",
  -- "wgsl",
  -- "yaml",
}

-- Set any to false that you want disabled in here.
-- take a look at the autocommands file in lua/config for more information
-- Default value is true if left blank
M.autocommands = {
  alpha_folding = true,
  cmp = true,
  css_colorizer = true,
  remember_file_state = true,
  session_saved_notification = true,
  treesitter_folds = true,
  whitespace_cleanup = true,
}

-- set to false to disable plugins
-- Default value is true if left blank
M.enable_plugins = {
  aerial = true,
  alpha = true,
  astrotheme = true,
  autopairs = true,
  autotag = true,
  bufferline = true,
  cmp = true,
  colorizer = true,
  context = true,
  dap = true,
  gitsigns = true,
  hop = true,
  img_clip = true,
  indent_blankline = true,
  indent_blankline_rainbow = true,
  lazydev = true,
  lsp = true,
  lualine = true,
  neoscroll = true,
  neotree = true,
  noice = true,
  notify = true,
  null_ls = true,
  project = true,
  rainbow = true,
  scope = true,
  session_manager = true,
  telescope = true,
  toggleterm = true,
  treesitter = true,
  trouble = true,
  twilight = true,
  ufo = true,
  whichkey = true,
  zen = true,
}

-- add extra plugins in here
M.plugins = {
  -- {
  --   "simrat39/rust-tools.nvim",
  --   ft = "rust",
  --   cond = M.enable_plugins.rust_tools,
  --   config = function()
  --     require("user.plugin-configs.rust-tools")
  --   end,
  -- },
  -- {
  --   "folke/tokyonight.nvim",
  --   lazy = false,
  --   cond = M.enable_plugins.tokyonight,
  --   config = function()
  --     require("user.plugin-configs.tokyonight")
  --   end,
  -- },
  -- {
  --   "catppuccin/nvim",
  --   lazy = false,
  --   cond = M.enable_plugins.catppuccin,
  --   config = function()
  --     require("user.plugin-configs.catppuccin")
  --   end,
  -- },
  -- {
  --   "EdenEast/nightfox.nvim",
  --   lazy = false,
  --   cond = M.enable_plugins.nightfox,
  --   config = function()
  --     require("user.plugin-configs.nightfox")
  --   end,
  -- },
  -- {
  --   "loctvl842/monokai-pro.nvim",
  --   lazy = false,
  --   cond = M.enable_plugins.monokai_pro,
  --   config = function()
  --     require("user.plugin-configs.monokai-pro")
  --   end,
  -- },
}

M.lsp_configs = {
  -- clangd = {
  --   capabilities = {
  --     offsetEncoding = { "utf-8", "utf-16" },
  --     textDocument = {
  --       completion = {
  --         editsNearCursor = true,
  --       },
  --     },
  --   },
  --   cmd = { "clangd" },
  --   filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
  -- },
  lua_ls = {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    settings = {
      Lua = {
        diagnostics = {
          disable = { "missing-fields" },
          globals = { "vim" },
        },
        hint = {
          enable = true,
        },
      },
    },
    log_level = 2,
  },
  -- basedpyright = {
  --   cmd = { "basedpyright-langserver", "--stdio" },
  --   filetypes = { "python" },
  --   settings = {
  --     basedpyright = {
  --       analysis = {
  --         autoSearchPaths = true,
  --         diagnosticMode = "openFilesOnly",
  --         useLibraryCodeForTypes = true,
  --         typeCheckingMode = "standard",
  --       },
  --     },
  --   },
  -- },
  -- taplo = {
  --   cmd = { "taplo", "lsp", "stdio" },
  --   filetypes = { "toml" },
  -- },
  -- ruby_lsp = {
  --   cmd = { "ruby-lsp" },
  --   filetypes = { "ruby", "eruby" },
  --   init_options = { "auto" },
  -- },
}

-- add extra configuration options here, like extra autocmds etc.
-- feel free to create your own separate files and require them in here
M.custom_conf = function()
  -- greeting upon startup
  utils.notify_info("Here be dragons! Fear is the mind killer.", "<== lususnaturae ==>")

  -- set color scheme
  -- utils.colors("catppuccin")
  -- utils.colors("tokyonight")
  -- utils.colors("nightfox")
  -- utils.colors("astrotheme")
  -- utils.colors("astromars")
  -- utils.colors("monokai-pro")
  -- utils.colors("monokai-pro-machine")
  -- utils.colors("monokai-pro-octagon")

  -- require("user.usercommands") -- example of using a file for custom usercommands
end

return M
