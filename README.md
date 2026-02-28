# LushNvim

## About

- LushNvim is a small yet fully featured IDE-like configuration for Neovim.
- It's ready to use out of the box but meant to be almost completely and very simply modified.
- No compromise on full IDE-like functionality is made while remaining small and simple.
- Its goal is to be a typical great personal configuration that also fulfills the role of a distro.
- Full LSP feature support with autocompletion.
- A new user should be able to understand the entire config in an afternoon and master it in a day.


## Prerequisites

- Neovim v0.10.0+ (latest stable recommended)
- `git`, `make`, `pip`, `python3`, `npm`, `node`, `cargo`, `ripgrep`
- A [Nerd Font](https://www.nerdfonts.com/) for proper icon rendering
- Resolve `EACCESS` permissions with npm: https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally

### Optional

- `lazygit` — integrated git UI via `<leader>gg`
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

LushNvim includes built-in diagnostic commands:

| Command | Description |
|---------|-------------|
| `:checkhealth lush` | Check nvim version, external tools, mason packages, LSP servers, treesitter parsers |
| `:LushInfo` | Show current buffer's LSP clients, formatters, linters, DAP adapter, treesitter status |
| `:LushUpdate` | Update plugins, mason packages, and treesitter parsers |
| `:LushInit` | Create user config from example template (first-run) |
| `:LushReload` | Hot-reload config (options, keybindings, autocommands) |


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
| `<leader>u` | UI | UI toggles (spell, wrap, zen, inlay hints) |
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
| `<leader>gg` | Lazygit |
| `<leader>xx` | Diagnostics |
| `<leader>?` | Show keymaps |


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
    autocommands.lua    Autocommand definitions
    keybindings.lua     Global keybindings
    languages.lua       Language bundle definitions
    lazy.lua            Plugin specifications
    lsp.lua             LSP and completion setup
    options.lua         Default Neovim options
    usercommands.lua    Built-in user commands (:LushInfo, :LushUpdate, etc.)
    utils.lua           Utility functions
  user/             Your personal configuration
    config.lua          Main user config (copy from example_user_config.lua)
    usercommands.lua    Custom user commands
    plugin-configs/     Custom plugin configurations
  lush/
    health.lua          Health check module (:checkhealth lush)
after/plugin/       Plugin-specific configuration (one file per plugin/feature)
init.lua            Entry point
```


## Copyright

Michael Berry 2026


## License

This project is licensed under the GNU General Public License version 3

See the file COPYING for more information

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
