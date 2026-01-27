# LususNvim

![Alt text](screenshots/lususnvim_alpha.png)
![Alt text](screenshots/lususnvim_editing.png)
![Alt text](screenshots/lususnvim_lazygit.png)

## About

- LususNvim is a small yet fully featured IDE-like configuration for neovim.
- It's ready to use out of the box but meant to be almost completely and very simply modified.
- No compromise on full IDE-like functionality is made while remaining small and simple.
- Its goal is to be a typical great personal configuration that also fulfills the role of a distro.
- Full LSP feature support with autocompletion.


## Latest Release

v0.1.0


## Prerequisites

- Make sure you have installed the latest version of Neovim v0.10.0+.
- Have `git`, `make`, `pip`, `python`, `npm`, `node`, `cargo` and `ripgrep` installed on your system.
- Resolve `EACCESS` permissions with npm https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally
- A Nerd font is necessary for proper rendering.

## Optional Prerequisites

- Install `lazygit`. This enables `<leader>gg` to launch lazygit for integrated and enhanced Git experience.
- Install `btop` for process management.
- Install `gdu` for disk usage analytics.
- Install `tokei` for project lines of code information, `<leader>tk`.


## Installation

Direct installation on a UNIX-like operating system.

    $ git clone https://github.com/berrym/LususNvim.git ~/.config/nvim


Recommended installation to a non-default physical location.

    $ git clone https://github.com/berrym/LususNvim.git # into directory of user's choice
    $ ln -s ~/path/to/LususNvim ~/.config/nvim


## Configuration

Create a user config directory under the lua directory in the LususNvim root directory:

    $ mkdir -pv ~/path/to/LususNvim/lua/user
    $ cd ~/path/to/LususNvim/lua/user
    $ cp ../example_user_config.lua config.lua

Edit `config.lua` following the commentary to customize your setup.


## Post installation

- After installation run nvim and let LususNvim download and configure its requirements.
- This process can take several minutes so be patient.
- After the initial setup has finished close nvim then reopen it.
  - You may have luck after installation just opening the start menu, `<leader>;`


## Keybindings

LususNvim uses a mnemonic keybinding system with which-key integration. Press `<leader>` (space) and wait to see available groups with icons.

### Leader Groups

| Prefix | Purpose | Description |
|--------|---------|-------------|
| `<leader>a` | AI/Claude | Claude Code integration |
| `<leader>b` | Buffer | Buffer management |
| `<leader>c` | Code/LSP | LSP actions (code action, rename, format) |
| `<leader>d` | Debug | DAP debugging |
| `<leader>f` | Find | Telescope searches |
| `<leader>g` | Git | Git operations and hunks |
| `<leader>n` | Explorer | Neo-tree file explorer |
| `<leader>q` | Quit | Quit and close operations |
| `<leader>s` | Session | Session save/load |
| `<leader>t` | Tab | Tab management |
| `<leader>u` | UI | UI toggles (spell, wrap, zen) |
| `<leader>w` | Window | Window splits and navigation |
| `<leader>x` | Diagnostics | Trouble diagnostics |

### Direct Navigation

| Key | Action |
|-----|--------|
| `Ctrl+h/j/k/l` | Navigate between windows |
| `[b` / `]b` | Previous/next buffer |
| `[t` / `]t` | Previous/next tab |
| `[d` / `]d` | Previous/next diagnostic |
| `[c` / `]c` | Previous/next git hunk |
| `<C-\>` | Toggle terminal |

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

- On startup you'll be greeted with a menu with many options.
  - What options appear depends on what features you have enabled or if you're in a git repo etc.
- LususNvim uses which-key so it will help guide the user on which keystrokes perform commands.
  - `?` will bring up buffer local keybindings if in a window other than the main, e.g. neotree.
- `<C-\>` (Ctrl+backslash) will toggle a retractable terminal.
- Most commands are executed in Normal mode, and start by pressing the `<leader>` which is space.
- Neotree is a file explorer, when in Normal mode it can be accessed with `<leader>n`:
  - `<leader>nl` opens neotree in a window on the left side.
  - `<leader>nr` opens neotree in a window on the right.
  - `<leader>nf` opens neotree in a floating window.
  - `<leader>nn` opens neotree like neovim's built-in file explorer netrw.
- Bufferline is a tabline for neovim buffers, `<leader>b` prefixes buffer related commands:
  - `<leader>bp` switches to the previous buffer tab.
  - `<leader>bn` switches to the next buffer tab.
  - `[b` and `]b` also work for quick buffer navigation.
  - which-key will help you with all the available keybindings.
- Sessions can be created and restored:
  - `<leader>ss` saves the current session.
  - `<leader>sl` will load a saved session.
  - On startup pressing `l` at the start menu will load your last session.
- As mentioned LSP and autocompletion come out of the box:
  - When performing a completion with an LSP server `<C-space>` will toggle documentation.
  - If diagnostics indicate error pressing `<leader>xx` will open up trouble for more verbose info.
  - LSP actions are available under `<leader>c` (code action, rename, format, etc.)
- Lazy is the package manager it can be used with the command `:Lazy`
  - Extra plugins can easily be added and managed by editing `lua/user/config.lua`.
- Mason is the plugin used to manage LSP related tools:
  - `:Mason` opens the main ui for Mason
  - `:MasonInstall` will install extensions, `:MasonUninstall` does the opposite.
  - Configuration of Mason and LSP is easily managed by editing the user config.
- The command `:LususUpdate` can be used to update most of what gets installed.
- `:AstroTransparencyOn` and `:AstroTransparencyOff` can be used to toggle transparency.
- If you like controlling your session using the startup screen it can be opened with `<leader>;`
- There is much more but this represents a basic starting point.


## Copyright

Michael Berry 2025


## License

This project is licensed under the GNU General Public License version 3

See the file COPYING for more information

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
