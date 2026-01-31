-- config.lua file where user configuration for LushNvim happens

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
-- function paramater 'b' is shorthand for builtin.
M.setup_sources = function(b)
  return {
    b.completion.luasnip,
    b.completion.tags,
    b.formatting.clang_format,
    b.formatting.stylua,
    b.formatting.cbfmt,
    b.formatting.shfmt,
    -- b.formatting.gofumpt, -- gopls handles this natively
    -- b.formatting.goimports_reviser, -- gopls handles imports better
    -- b.formatting.black, -- Replaced by ruff LSP
    b.formatting.prettierd.with({
      filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "html",
        "css",
      },
    }),
    b.formatting.cmake_format,
    b.diagnostics.checkmake,
    -- b.diagnostics.pylint, -- Replaced by ruff LSP
    -- b.diagnostics.revive, -- gopls staticcheck covers this
    -- b.diagnostics.swiftlint,
    b.diagnostics.cmake_lint,
    b.code_actions.gitrebase,
    b.code_actions.gitsigns,
    b.code_actions.gomodifytags,
    b.code_actions.refactoring,
    b.hover.dictionary,
  }
end

-- add mason sources to auto-install
M.mason_ensure_installed = {
  null_ls = {
    "stylua",
    "lua-language-server",
    "clangd",
    "clang-format",
    "codelldb",
    "basedpyright",
    "ruff", -- Replaces black, pylint, isort - all-in-one linter/formatter
    -- "black", -- Replaced by ruff
    -- "pylint", -- Replaced by ruff
    -- NOTE: For rust-analyzer, use `rustup component add rust-analyzer` instead
    -- This keeps rust-analyzer version synced with your toolchain (recommended by rustaceanvim)
    "gopls",
    "gomodifytags",
    -- "gofumpt", -- gopls handles formatting with gofumpt enabled
    -- "goimports-reviser", -- gopls handles imports natively (faster)
    -- "revive", -- gopls staticcheck covers most linting
    "prettierd",
    "typescript-language-server",
    "css-lsp",
    "html-lsp",
    "json-lsp",
    "autotools-language-server",
    "checkmake",
    "mesonlsp",
    "shfmt",
    "ruby-lsp",
    "solargraph",
    -- "swiftlint",
  },
  dap = {
    "python",
  },
}

-- add servers to be used for auto formatting here
M.formatting_servers = {
  ["null_ls"] = {
    "lua",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "html",
    "css",
    "json",
    "sh",
    "bash",
    "zsh",
    "c",
    "cpp",
    "objc",
    "objcpp",
    "cuda",
    "proto",
    "python",
    "rust",
    "go",
    "meson",
    "cmake",
    "markdown",
    "ruby",
  },
}

-- add treesitter parsers
M.treesitter_ensure_installed = {
  "asm",
  "bash",
  "c",
  "cmake",
  "comment",
  "cpp",
  "css",
  "csv",
  "cuda",
  "diff",
  "disassembly",
  "dockerfile",
  "xml",
  "gitattributes",
  "gitcommit",
  "gitignore",
  "glsl",
  "go",
  "gomod",
  "gosum",
  "haskell",
  "html",
  "hyprlang",
  "java",
  "javascript",
  "jsdoc",
  "json",
  "json5",
  "latex",
  "lua",
  "luap",
  "luau",
  "make",
  "markdown",
  "meson",
  "ninja",
  "objdump",
  "printf",
  "python",
  "regex",
  "ron",
  "ruby",
  "rust",
  "scss",
  "toml",
  "tsx",
  "wgsl",
  "yaml",
}

-- Set any to false that you want disabled in here.
-- take a look at the autocommands file in lua/config for more information
-- Default value is true if left blank
M.autocommands = {
  alpha_folding = true,
  auto_reload = true, -- Auto-reload buffers when files change externally
  autochdir = true,
  claude_code_reload = true, -- Auto-reload buffers when Claude Code edits files
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
  snacks = true,
  telescope = true,
  toggleterm = true,
  treesitter = true,
  trouble = true,
  twilight = true,
  ufo = true,
  whichkey = true,
  zen = true,
  -- AI Coding Assistant
  claudecode = true,
  -- Rust
  rustaceanvim = true,
}

-- add extra plugins in here
M.plugins = {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    cond = M.enable_plugins.tokyonight,
    config = function()
      require("user.plugin-configs.tokyonight")
    end,
  },
  {
    "catppuccin/nvim",
    lazy = false,
    cond = M.enable_plugins.catppuccin,
    config = function()
      require("user.plugin-configs.catppuccin")
    end,
  },
  {
    "EdenEast/nightfox.nvim",
    lazy = false,
    cond = M.enable_plugins.nightfox,
    config = function()
      require("user.plugin-configs.nightfox")
    end,
  },
  {
    "loctvl842/monokai-pro.nvim",
    lazy = false,
    cond = M.enable_plugins.monokai_pro,
    config = function()
      require("user.plugin-configs.monokai-pro")
    end,
  },
  -- AI Coding Assistant
  {
    "coder/claudecode.nvim",
    event = "VeryLazy",
    cond = M.enable_plugins.claudecode,
    opts = {
      -- Terminal window settings
      terminal = {
        show_native_term_exit_tip = false,
      },
      -- Diff settings
      diff_provider = "snacks", -- or "native" or "mini_diff"
    },
  },
}

M.lsp_configs = {
  clangd = {
    capabilities = {
      offsetEncoding = { "utf-8", "utf-16" },
      textDocument = {
        completion = {
          editsNearCursor = true,
        },
      },
    },
    cmd = {
      "clangd",
      "--background-index", -- Index project in background
      "--clang-tidy", -- Enable clang-tidy diagnostics
      "--header-insertion=iwyu", -- Include What You Use
      "--completion-style=detailed", -- Detailed completion items
      "--function-arg-placeholders", -- Placeholders for function args
      "--fallback-style=llvm", -- Fallback formatting style
      "--pch-storage=memory", -- Store PCH in memory (faster)
    },
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
    init_options = {
      usePlaceholders = true,
      completeUnimported = true,
      clangdFileStatus = true,
    },
    settings = {
      clangd = {
        InlayHints = {
          Enabled = true,
          ParameterNames = true,
          DeducedTypes = true,
          Designators = true,
        },
      },
    },
  },
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
  basedpyright = {
    cmd = { "basedpyright-langserver", "--stdio" },
    filetypes = { "python" },
    settings = {
      basedpyright = {
        -- Disable import organization (ruff handles this)
        disableOrganizeImports = true,
        analysis = {
          autoSearchPaths = true,
          diagnosticMode = "openFilesOnly",
          useLibraryCodeForTypes = true,
          -- "off", "basic", "standard", "strict", "all"
          typeCheckingMode = "standard",
          -- Ignore all files for linting (ruff handles this)
          ignore = { "*" },
        },
      },
    },
  },
  ruff = {
    cmd = { "ruff", "server" },
    filetypes = { "python" },
    init_options = {
      settings = {
        -- Ruff language server settings
        lineLength = 100,
        -- Enable all default rules plus isort
        lint = {
          select = { "E", "F", "W", "I" }, -- E/F/W: pyflakes/pycodestyle, I: isort
        },
        format = {
          -- Use the same style as black
          lineLength = 100,
        },
      },
    },
  },
  gopls = {
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    settings = {
      gopls = {
        -- Formatting
        gofumpt = true, -- Use gofumpt for stricter formatting
        -- Linting & Analysis
        staticcheck = true,
        analyses = {
          nilness = true,
          unusedparams = true,
          unusedwrite = true,
          useany = true,
          shadow = true,
        },
        -- Completion
        completeUnimported = true,
        usePlaceholders = true,
        -- Codelenses
        codelenses = {
          generate = true,
          gc_details = true,
          run_govulncheck = true,
          test = true,
          tidy = true,
          upgrade_dependency = true,
          vendor = true,
        },
        -- Hints (inlay hints)
        hints = {
          assignVariableTypes = true,
          compositeLiteralFields = true,
          compositeLiteralTypes = true,
          constantValues = true,
          functionTypeParameters = true,
          parameterNames = true,
          rangeVariableTypes = true,
        },
        -- Semantic tokens
        semanticTokens = true,
        -- Diagnostics
        diagnosticsDelay = "500ms",
        diagnosticsTrigger = "Edit",
      },
    },
  },
  taplo = {
    cmd = { "taplo", "lsp", "stdio" },
    filetypes = { "toml" },
  },
  ruby_lsp = {
    cmd = { "ruby-lsp" },
    filetypes = { "ruby", "eruby" },
    init_options = { "auto" },
  },
}

-- add extra configuration options here, like extra autocmds etc.
M.custom_conf = function()
  -- local lspconfig = require("lspconfig")
  -- lspconfig.sourcekit.setup({
  --   capabilities = {
  --     workspace = {
  --       didChangeWatchedFiles = {
  --         dynamicRegistration = true,
  --       },
  --     },
  --   },
  -- })

  -- greeting upon startup
  utils.notify_info("Here be dragons! Fear is the mind killer.", "<== lususnaturae ==>")

  -- set color scheme
  -- utils.colors("catppuccin")
  utils.colors("tokyonight-night")
  -- utils.colors("nightfox")
  -- utils.colors("duskfox")
  -- utils.colors("astrotheme")
  -- utils.colors("astromars")
  -- utils.colors("monokai-pro")
  -- utils.colors("monokai-pro-machine")
  -- utils.colors("monokai-pro-octagon")

  require("user.usercommands")
end

return M
