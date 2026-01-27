require("catppuccin").setup({
  flavour = "mocha", -- latte, frappe, macchiato, mocha, auto
  background = {     -- :h background
    light = "latte",
    dark = "mocha",
  },
  transparent_background = true, -- disables setting the background color.
  show_end_of_buffer = true,     -- shows the '~' characters after the end of buffers
  term_colors = true,            -- sets terminal colors (e.g. `g:terminal_color_0`)
  dim_inactive = {
    enabled = true,              -- dims the background color of inactive window
    shade = "dark",
    percentage = 0.15,           -- percentage of the shade to apply to the inactive window
  },
  no_italic = false,             -- Force no italic
  no_bold = false,               -- Force no bold
  no_underline = false,          -- Force no underline
  styles = {                     -- Handles the styles of general hi groups (see `:h highlight-args`):
    comments = { "italic" },     -- Change the style of comments
    conditionals = { "italic" },
    loops = {},
    functions = {},
    keywords = {},
    strings = {},
    variables = {},
    numbers = {},
    booleans = {},
    properties = {},
    types = {},
    operators = {},
    -- miscs = {}, -- Uncomment to turn off hard-coded styles
  },
  custom_highlights = {},
  default_integrations = true,
  integrations = {
    aerial = true,
    alpha = true,
    lsp_trouble = true,
    cmp = true,
    gitsigns = true,
    bufferline = true,
    indent_blankline = {
      enabled = true,
      scope_color = "lavender", -- catppuccin color (eg. `lavender`) default: text
      colored_indent_levels = true,
    },
    neotree = true,
    noice = true,
    telescope = true,
    treesitter = true,
    mason = true,
    which_key = true,
    notify = true,
    ufo = true,
    -- for more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
  },
})
