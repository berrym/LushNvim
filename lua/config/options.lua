local vim_opts = require("config.utils").vim_opts
vim.opt.shortmess:append("sIW")

vim_opts({
  opt = {
    autochdir = false, -- deprecated, breaks with some plugins, config.autocommands handles this
    autoread = true, -- Auto-reload files changed outside of Neovim
    breakindent = true,
    breakindentopt = "shift:2,min:40,sbr",
    clipboard = "unnamedplus",
    colorcolumn = "100",
    confirm = true,
    cursorline = true,
    cursorlineopt = "number",
    -- Default to soft tabs (4 spaces). Filetypes that need a different width
    -- are handled per-filetype in autocommands.lua's indent_config. Filetypes
    -- whose canonical tool enforces hard tabs (e.g. Go's gofmt) flip back to
    -- `expandtab = false` in their own FileType autocmds.
    expandtab = true,
    shiftwidth = 4,
    softtabstop = 4,
    tabstop = 4,
    foldenable = true,
    foldmethod = "expr",
    foldexpr = "v:lua.vim.treesitter.foldexpr()",
    foldlevel = 99,
    foldlevelstart = 99,
    foldopen = "jump,block,hor,mark,percent,quickfix,search,tag,undo",
    guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20",
    mouse = "a",
    hlsearch = true,
    ignorecase = true,
    incsearch = true,
    laststatus = 3,
    -- linebreak = true,
    number = true,
    numberwidth = 6,
    relativenumber = true,
    scrolloff = 8,
    sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions",
    sidescrolloff = 8,
    -- showbreak = "=>>",
    showmode = false,
    signcolumn = "yes",
    smartcase = true,
    swapfile = false,
    textwidth = 100,
    termguicolors = true,
    undofile = true,
    -- Global rounded border for every floating window (LSP hover/signature,
    -- diagnostics, snacks pickers, etc.). Nvim 0.11+ honors this for all
    -- floats by default; plugins that override get tuned individually.
    winborder = "rounded",
    wrap = false,
    writebackup = false,
  },
})

local exist, user_config = pcall(require, "user.config")
local opts = exist and type(user_config) == "table" and user_config.options or {}
vim_opts(opts)
