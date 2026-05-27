# LushNvim

## About

LushNvim is a fully featured IDE-like Neovim configuration that you can understand in an afternoon and master in a day.

The big Neovim distros — LazyVim, AstroNvim, NvChad — give you everything out of the box, but they wrap Neovim in layers of abstraction. Want to change a keybinding? Learn their keybinding API. Want to configure an LSP server? Use their LSP wrapper. Want to add a language? Navigate their extras system. The power is there, but the cost is that customization requires learning the distro itself, not just Neovim. For many developers that's days of reading documentation before they can confidently change anything.

LushNvim solves the opposite problem. It uses native Neovim APIs directly — `vim.keymap.set`, `vim.lsp.config`, `vim.api.nvim_create_autocmd` — with no abstraction layer in between. Every plugin config lives in its own file under `after/plugin/`. You can open any single file and understand it completely without tracing through framework internals. The entire config is flat Lua that reads top to bottom.

What makes it work as a handoff:

- **One file to customize** — `lua/user/config.lua` controls everything: plugins, LSP servers, formatters, debuggers, treesitter parsers, and autocommand behavior. Toggle any feature with a single boolean.
- **Language bundles** — set `M.languages = { "python", "go", "rust" }` and get LSP, formatting, debugging, and treesitter configured automatically. Override any default with a manual entry that always wins.
- **No abstraction tax** — what you learn configuring LushNvim is Neovim itself. That knowledge transfers everywhere.
- **Built-in diagnostics** — `:checkhealth lush` verifies your setup, `:LushInfo` shows what's active in the current buffer.
- **Full IDE functionality** — LSP with autocompletion, DAP debugging with persistent breakpoints, git integration, file explorer, fuzzy finding, session management, and more. No compromises on capability.


## Prerequisites

- Neovim v0.11.0+ (uses `vim.lsp.config`, `vim.opt.winborder`, and other 0.11 APIs)
- `git`, `make`, `pip`, `python3`, `npm`, `node`, `cargo`, `ripgrep`
- A [Nerd Font](https://www.nerdfonts.com/) for proper icon rendering
- Resolve `EACCESS` permissions with npm: https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally

### Optional

- `lazygit` — integrated floating git UI via `<leader>gg` (auto-themed to nvim colorscheme)
- `fd` — faster file finding for Telescope
- `btop` — process management via `<leader>tb`
- `gdu` — disk usage analytics via `<leader>tg`
- `tokei` — project lines of code via `<leader>tk`


## Installation

Direct installation:

    $ git clone https://github.com/berrym/LushNvim.git ~/.config/nvim

Recommended — clone to a separate location and symlink:

    $ git clone https://github.com/berrym/LushNvim.git ~/path/to/LushNvim
    $ ln -s ~/path/to/LushNvim ~/.config/nvim


## Configuration

LushNvim is configured through a single file. To set up your personal configuration:

    $ cp ~/.config/nvim/lua/example_user_config.lua ~/.config/nvim/lua/user/config.lua

Edit `lua/user/config.lua` to customize your setup.

### Language Bundles

The fastest way to set up language support. Add one line to your config and get LSP, formatting, debugging, and treesitter configured automatically:

```lua
M.languages = { "c", "python", "go", "rust", "lua", "web", "bash", "toml", "yaml" }
```

Each bundle auto-populates `mason_ensure_installed`, `lsp_configs`, `treesitter_ensure_installed`, and `formatting_servers` with sensible defaults. You can still override any individual table — manual entries always take precedence over bundle defaults.

Available bundles: `c` (includes cmake + meson), `python`, `go`, `rust`, `lua`, `web` (JS/TS/HTML/CSS/JSON), `bash`, `toml`, `yaml`, `ruby`, `zig`, `docker`, `perl`, `java`

### Manual Configuration

For full control, configure each table individually in `lua/user/config.lua`:

- **`M.enable_plugins`** — toggle any plugin on/off (default: everything enabled)
- **`M.lsp_configs`** — per-server LSP configuration
- **`M.mason_ensure_installed`** — tools to auto-install via Mason (LSP servers, formatters, DAP adapters)
- **`M.treesitter_ensure_installed`** — language parsers
- **`M.formatting_servers`** — filetypes mapped to formatters
- **`M.setup_sources()`** — null-ls sources (formatters, linters, code actions)
- **`M.autocommands`** — toggle autocommand behaviors
- **`M.plugins`** — add extra plugins
- **`M.custom_conf()`** — custom startup hook (colorscheme, user commands, etc.)

Both approaches can be combined — use bundles for the base and override specific settings manually.


## Post Installation

- Run `nvim` and let LushNvim download and configure its requirements.
- This process can take several minutes on first launch.
- On first run, if no user config exists, LushNvim will show a welcome message.
  - Run `:LushInit` to automatically create your config from the example template.
  - Or manually: `cp lua/example_user_config.lua lua/user/config.lua`
- After the initial setup, close and reopen nvim.
- Run `:checkhealth lush` to verify everything is installed correctly.


## Health Check and Diagnostics

LushNvim includes built-in commands for inspection, configuration, and reload:

| Command | Description |
|---------|-------------|
| `:checkhealth lush` / `:LushHealth` | Full diagnostic: nvim version, external tools, mason packages, LSP servers, treesitter parsers, snacks modules, registry health |
| `:LushStatus` | At-a-glance config panel: colorscheme, statusline, enabled features, snacks modules, LSP clients, DAP adapters |
| `:LushInfo` | Current buffer's LSP clients, formatters, linters, DAP adapter, treesitter status |
| `:LushFeatures` | Telescope picker to toggle any `enable_plugins` flag with persistence and auto-reload (`<Tab>` to multi-select, `<C-a>` to batch-apply) |
| `:LushColors` | Live-preview colorscheme picker; selection persists to `user/config.lua` |
| `:LushStatusline` | Live-preview statusline style picker; selection persists |
| `:LushUpdate` | Update plugins, mason packages, and treesitter parsers |
| `:LushReload` | Hot-reload config — clears tracked keymaps and options, re-runs after/plugin, restarts LSPs |
| `:LushLayoutReset` | Escape hatch when a Claude diff layout gets stuck |
| `:LushInit` | Create `user/config.lua` from the example template (first-run helper) |

`:LushReload` is reload-aware:
- **Keymap registry** — every keymap LushNvim binds is tracked; on reload they're cleared first so disabled features actually unbind.
- **Option registry** — same for `vim.opt`; removing an option from `M.options` actually unsets it on reload.
- **after/plugin re-source** — every plugin's setup is re-run, so config changes take effect without restart.
- **LSP restart** — already-attached clients pick up new `lsp_configs` automatically.


## Keybindings

LushNvim uses a mnemonic keybinding system with which-key integration. Press `<leader>` (space) and wait to see available groups with icons.

### Leader Groups

| Prefix | Purpose | Description |
|--------|---------|-------------|
| `<leader>a` | AI/Claude | Claude Code integration |
| `<leader>b` | Buffer | Buffer management |
| `<leader>c` | Code/LSP | LSP actions (code action, rename, format) |
| `<leader>d` | Debug | DAP debugging (breakpoints, step, terminate) |
| `<leader>f` | Find | Telescope searches |
| `<leader>g` | Git | Git operations and hunks |
| `<leader>n` | Explorer | Neo-tree file explorer |
| `<leader>q` | Quit | Quit and close operations |
| `<leader>s` | Session | Session save/load |
| `<leader>t` | Tab | Tab management |
| `<leader>u` | UI | UI toggles + Lush pickers (features, status, health, colors, statusline) |
| `<leader>w` | Window | Window splits and navigation |
| `<leader>x` | Diagnostics | Trouble diagnostics |

### Language-Specific Leader Groups

| Prefix | Language | Examples |
|--------|----------|----------|
| `<leader>C` | C/C++ | Switch header/source, compile, debug |
| `<leader>G` | Go | Organize imports, struct tags, codelens |
| `<leader>p` | Python | Organize imports, fix all, format |
| `<leader>r` | Rust | Hover actions, runnables, expand macro |

### Direct Navigation

| Key | Action |
|-----|--------|
| `Ctrl+h/j/k/l` | Navigate between windows |
| `[b` / `]b` | Previous/next buffer |
| `[t` / `]t` | Previous/next tab |
| `[d` / `]d` | Previous/next diagnostic |
| `[c` / `]c` | Previous/next git hunk |
| `<C-\>` | Toggle terminal |
| `<Esc>` | Clear search highlights / dismiss notifications |

### Debugging

| Key | Action |
|-----|--------|
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | Conditional breakpoint |
| `<leader>dc` | Start / continue debugging |
| `<leader>di` | Step into |
| `<leader>do` | Step over |
| `<leader>dO` | Step out |
| `<leader>dt` | Terminate debug session |
| `<leader>du` | Toggle DAP UI |

### Common Operations

| Key | Action |
|-----|--------|
| `<leader>;` | Dashboard |
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>nl` | Neo-tree left |
| `<leader>gg` | Lazygit (auto-themed) |
| `<leader>gl` | Lazygit log (cwd) |
| `<leader>gL` | Lazygit log (current file) |
| `<leader>xx` | Diagnostics |
| `<leader>?` | Show keymaps |

### Lush pickers and toggles

| Key | Action |
|-----|--------|
| `<leader>uF` | `:LushFeatures` — toggle enable_plugins flags |
| `<leader>uS` | `:LushStatus` — config status panel |
| `<leader>uH` | `:LushHealth` — health report (opens in a new tab) |
| `<leader>uc` | `:LushColors` — colorscheme picker |
| `<leader>ul` | `:LushStatusline` — statusline style picker |
| `<leader>ur` | `:LushReload` — hot-reload config |
| `<leader>uR` | `:LushLayoutReset` — recover from stuck layout |
| `s` / `S` | Flash jump / treesitter (replaces hop) |


## Basic Usage

- On startup you'll be greeted with a dashboard with common actions.
  - What options appear depends on what features you have enabled and if you're in a git repo.
- LushNvim uses which-key so pressing `<leader>` (space) shows all available actions.
  - `?` will bring up buffer local keybindings in special windows (e.g. Neo-tree).
- `<C-\>` (Ctrl+backslash) toggles a floating terminal.
- Neo-tree file explorer: `<leader>nl` (left), `<leader>nr` (right), `<leader>nf` (float).
- Bufferline: `[b`/`]b` for quick buffer navigation, `<leader>b` for more options.
- Sessions: `<leader>ss` to save, `<leader>sl` to load, `l` on the dashboard for last session.
- LSP: autocompletion works out of the box, `<leader>c` for code actions, `<leader>xx` for diagnostics.
- Lazy package manager: `:Lazy` to manage plugins. Extra plugins added via `M.plugins` in user config.
- Mason: `:Mason` to manage LSP servers, formatters, and debuggers.
- CWD management: automatically changes to project root (via project.nvim) when inside a project, falls back to file directory otherwise. Special buffers (terminals, floating windows) never affect CWD.


## Project Structure

```
lua/
  config/           Core configuration (do not modify for personal settings)
    autocommands.lua    Autocommand definitions (layout guardians, format-on-save, etc.)
    keybindings.lua     Global keybindings (via utils.map for reload-aware tracking)
    languages.lua       Language bundle definitions
    lazy.lua            Plugin specifications (lean — most setup lives in after/plugin/)
    lsp.lua             LSP and completion setup
    options.lua         Default Neovim options
    usercommands.lua    :LushInfo, :LushStatus, :LushHealth, :LushReload, etc.
    utils.lua           Utility functions + keymap/option registries
  user/             Your personal configuration
    config.lua          Main user config (copy from example_user_config.lua)
    usercommands.lua    Custom user commands
    plugin-configs/     Custom plugin configurations
  lush/
    health.lua          :checkhealth lush module
    dashboard.lua       snacks.dashboard config (header, keys, footer)
    snacks_opts.lua     snacks.nvim opts builder (reload-aware)
    statuslines/        Lualine style definitions (lush, fox, evil, etc.)
after/plugin/       Plugin-specific configuration (one file per plugin/feature)
init.lua            Entry point
```

## snacks.nvim cluster

LushNvim leans on `snacks.nvim` (folke) for many features that used to be
separate plugins. Each snacks module is opt-in via a granular flag:

| Flag | Module | Replaces / Provides |
|------|--------|---------------------|
| `snacks_dashboard` | dashboard | Start screen (replaces alpha-nvim) |
| `snacks_indent` | indent + scope | Indent guides (replaces indent-blankline) |
| `snacks_scroll` | scroll | Smooth cursor scroll (replaces neoscroll) |
| `snacks_zen` | zen + dim | Focused mode (replaces zen-mode + twilight) |
| `snacks_lazygit` | lazygit | Auto-themed floating lazygit |
| `snacks_notifier` | notifier | (optional) replaces nvim-notify if disabled |
| `snacks_bigfile` | bigfile | Auto-disable expensive features on huge files |
| `snacks_quickfile` | quickfile | Fast first-frame render at startup |
| `snacks_words` | words | Highlight same-word occurrences |
| `snacks_bufdelete` | bufdelete | Layout-aware `:bdelete` |
| `snacks_toggle` | toggle | `<leader>u*` toggle infrastructure |
| `snacks_input` | input | Prettier `vim.ui.input` |
| `snacks_rename` | rename | LSP-aware file rename |
| `snacks_gitbrowse` | gitbrowse | Open file/line on GitHub/GitLab |
| `snacks_git` | git | Misc git helpers |
| `snacks_debug` | debug | `Snacks.debug.inspect`/`log`/`backtrace` |
| `snacks_win` | win | Floating-window helper (used by claudecode) |

Toggle any of these with `:LushFeatures` or edit `M.enable_plugins` in `user/config.lua`.


## Copyright

Michael Berry 2026


## License

This project is licensed under the GNU General Public License version 3

See the file COPYING for more information

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
