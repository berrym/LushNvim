-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║                          LushNvim Keybindings                             ║
-- ╠═══════════════════════════════════════════════════════════════════════════╣
-- ║  Leader Groups:                                                           ║
-- ║    <leader>a  AI/Claude     󰚩    <leader>b  Buffer      󰈔                ║
-- ║    <leader>c  Code/LSP           <leader>d  Debug                        ║
-- ║    <leader>f  Find               <leader>g  Git                          ║
-- ║    <leader>n  Explorer     󰙅    <leader>q  Quit        󰗼                ║
-- ║    <leader>s  Session      󱂬    <leader>t  Tab         󰓩                ║
-- ║    <leader>u  UI                 <leader>w  Window                       ║
-- ║    <leader>x  Diagnostics  󰒡                                              ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

local exist, user_config = pcall(require, "user.config")
local group = exist and type(user_config) == "table" and user_config.enable_plugins or {}
local enabled = require("config.utils").enabled

-- ══════════════════════════════════════════════════════════════════════════════
-- [1] Leader Key Setup (set in init.lua for early availability)
-- ══════════════════════════════════════════════════════════════════════════════
-- NOTE: mapleader is set in init.lua before lazy.nvim loads to ensure
-- <leader> mappings in after/plugin files use the correct key

local M = {}

-- ══════════════════════════════════════════════════════════════════════════════
-- [2] Helper Functions
-- ══════════════════════════════════════════════════════════════════════════════
local map = vim.keymap.set

-- ══════════════════════════════════════════════════════════════════════════════
-- [3] Direct Window Navigation (Ctrl+h/j/k/l)
-- ══════════════════════════════════════════════════════════════════════════════
map("n", "<C-h>", "<C-w>h", { desc = "Focus left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Focus down window" })
map("n", "<C-k>", "<C-w>k", { desc = "Focus up window" })
map("n", "<C-l>", "<C-w>l", { desc = "Focus right window" })

-- ══════════════════════════════════════════════════════════════════════════════
-- [4] Bracket Navigation
-- ══════════════════════════════════════════════════════════════════════════════

-- Buffer navigation (bracket style)
if enabled(group, "bufferline") then
  map("n", "[b", "<CMD>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
  map("n", "]b", "<CMD>BufferLineCycleNext<CR>", { desc = "Next buffer" })
end

-- Tab navigation (bracket style)
map("n", "[t", "<CMD>tabprevious<CR>", { desc = "Previous tab" })
map("n", "]t", "<CMD>tabnext<CR>", { desc = "Next tab" })

-- Diagnostic navigation (bracket style)
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })

-- ══════════════════════════════════════════════════════════════════════════════
-- [5] Leader Groups (Alphabetical)
-- ══════════════════════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────────────────────
-- <leader>a: AI/Claude Code 󰚩
-- ──────────────────────────────────────────────────────────────────────────────
if enabled(group, "claudecode") then
  map("n", "<leader>aa", "<CMD>ClaudeCode<CR>", { desc = "Toggle Claude Code terminal" })
  map("n", "<leader>af", "<CMD>ClaudeCodeFocus<CR>", { desc = "Focus Claude Code" })
  map("n", "<leader>ar", "<CMD>ClaudeCode --resume<CR>", { desc = "Resume conversation" })
  map("n", "<leader>aR", "<CMD>ClaudeCode --continue<CR>", { desc = "Continue conversation" })
  map("v", "<leader>as", "<CMD>ClaudeCodeSend<CR>", { desc = "Send selection to Claude" })
  map({ "n", "v" }, "<leader>ac", "<CMD>ClaudeCodeAdd<CR>", { desc = "Add to Claude context" })
  map("n", "<leader>ab", "<CMD>ClaudeCodeAdd %<CR>", { desc = "Add buffer to context" })
  map("n", "<leader>at", "<CMD>ClaudeCodeTreeAdd<CR>", { desc = "Add file from tree" })
  -- +Diff subgroup
  map("n", "<leader>ada", "<CMD>ClaudeCodeDiffAccept<CR>", { desc = "Accept diff" })
  map("n", "<leader>add", "<CMD>ClaudeCodeDiffDeny<CR>", { desc = "Deny diff" })
  -- +Position subgroup (uses snacks_win_opts for top/bottom support)
  map("n", "<leader>awl", function() _G.claudecode_set_position("left") end, { desc = "Window left" })
  map("n", "<leader>awr", function() _G.claudecode_set_position("right") end, { desc = "Window right" })
  map("n", "<leader>awt", function() _G.claudecode_set_position("top") end, { desc = "Window top" })
  map("n", "<leader>awb", function() _G.claudecode_set_position("bottom") end, { desc = "Window bottom" })
end

-- ──────────────────────────────────────────────────────────────────────────────
-- <leader>b: Buffer 󰈔
-- ──────────────────────────────────────────────────────────────────────────────
if enabled(group, "bufferline") then
  map("n", "<leader>bb", "<CMD>Telescope buffers previewer=false<CR>", { desc = "Buffer picker" })
  map("n", "<leader>bf", "<CMD>Telescope buffers<CR>", { desc = "Find buffer" })
  map("n", "<leader>bj", "<CMD>BufferLinePick<CR>", { desc = "Jump to buffer" })
  map("n", "<leader>bn", "<CMD>BufferLineCycleNext<CR>", { desc = "Next buffer" })
  map("n", "<leader>bp", "<CMD>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
  map("n", "<leader>bo", "<CMD>BufferLineCloseOthers<CR>", { desc = "Close other buffers" })
  map("n", "<leader>bh", "<CMD>BufferLineCloseLeft<CR>", { desc = "Close buffers to left" })
  map("n", "<leader>bl", "<CMD>BufferLineCloseRight<CR>", { desc = "Close buffers to right" })
  map("n", "<leader>bW", "<CMD>noautocmd w<CR>", { desc = "Save without formatting" })
end

if enabled(group, "snacks") then
  map("n", "<leader>bd", function() require("snacks").bufdelete() end, { desc = "Delete buffer" })
end

-- Buffer reload (always available)
map("n", "<leader>br", "<CMD>checktime<CR>", { desc = "Reload buffer" })
map("n", "<leader>bR", "<CMD>e!<CR>", { desc = "Force reload (discard changes)" })

-- ──────────────────────────────────────────────────────────────────────────────
-- <leader>c: Code/LSP  (LSP bindings added in lsp.lua LspAttach)
-- ──────────────────────────────────────────────────────────────────────────────
if enabled(group, "trouble") then
  map("n", "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Symbols (Trouble)" })
  map("n", "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", { desc = "LSP info (Trouble)" })
end

-- ──────────────────────────────────────────────────────────────────────────────
-- <leader>d: Debug
-- ──────────────────────────────────────────────────────────────────────────────
if enabled(group, "dap") then
  local dap = require("dap")
  map("n", "<leader>dc", dap.continue, { desc = "Continue" })
  map("n", "<leader>dn", dap.step_over, { desc = "Step over" })
  map("n", "<leader>di", dap.step_into, { desc = "Step into" })
  map("n", "<leader>do", dap.step_out, { desc = "Step out" })
  map("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
  map("n", "<leader>dq", function() dap.disconnect({ terminateDebuggee = true }) end, { desc = "Quit debugger" })
  map("n", "<leader>du", function() require("dapui").toggle() end, { desc = "Toggle DAP UI" })
end

-- ──────────────────────────────────────────────────────────────────────────────
-- <leader>f: Find
-- ──────────────────────────────────────────────────────────────────────────────
if enabled(group, "telescope") then
  map("n", "<leader>ff", "<CMD>Telescope git_files<CR>", { desc = "Find files (git)" })
  map("n", "<leader>fF", "<CMD>Telescope find_files<CR>", { desc = "Find all files" })
  map("n", "<leader>fg", "<CMD>Telescope live_grep<CR>", { desc = "Live grep" })
  map("n", "<leader>fw", "<CMD>Telescope grep_string<CR>", { desc = "Grep word under cursor" })
  map("n", "<leader>fb", "<CMD>Telescope buffers<CR>", { desc = "Buffers" })
  map("n", "<leader>fh", "<CMD>Telescope help_tags<CR>", { desc = "Help tags" })
  map("n", "<leader>fr", "<CMD>Telescope oldfiles<CR>", { desc = "Recent files" })
  map("n", "<leader>fp", "<CMD>Telescope projects<CR>", { desc = "Projects" })
  map("n", "<leader>fa", "<CMD>Telescope aerial<CR>", { desc = "Aerial symbols" })
  map("n", "<leader>fm", "<CMD>Telescope marks<CR>", { desc = "Marks" })
  map("n", "<leader>fR", "<CMD>Telescope resume<CR>", { desc = "Resume search" })
end

-- ──────────────────────────────────────────────────────────────────────────────
-- <leader>g: Git  (hunks via gitsigns on_attach)
-- ──────────────────────────────────────────────────────────────────────────────
if enabled(group, "toggleterm") then
  map("n", "<leader>gg", function() require("config.terminal").lazygit_toggle() end, { desc = "Lazygit" })
end

if enabled(group, "snacks") then
  map("n", "<leader>gB", function() require("snacks").gitbrowse() end, { desc = "Git browse" })
end

-- ──────────────────────────────────────────────────────────────────────────────
-- <leader>n: Explorer 󰙅
-- ──────────────────────────────────────────────────────────────────────────────
if enabled(group, "neotree") then
  map("n", "<leader>nn", "<CMD>Neotree toggle current<CR>", { desc = "Toggle fullscreen" })
  map("n", "<leader>nl", "<CMD>Neotree toggle left<CR>", { desc = "Toggle left" })
  map("n", "<leader>nr", "<CMD>Neotree toggle right<CR>", { desc = "Toggle right" })
  map("n", "<leader>nf", "<CMD>Neotree reveal float<CR>", { desc = "Toggle float" })
end

-- ──────────────────────────────────────────────────────────────────────────────
-- <leader>q: Quit 󰗼
-- ──────────────────────────────────────────────────────────────────────────────
map("n", "<leader>qq", "<CMD>qa<CR>", { desc = "Quit all" })
map("n", "<leader>qQ", "<CMD>qa!<CR>", { desc = "Quit without saving" })
map("n", "<leader>qw", "<CMD>close<CR>", { desc = "Close window" })
map("n", "<leader>qb", "<CMD>bdelete<CR>", { desc = "Close buffer" })
map("n", "<leader>qa", "<CMD>wqa<CR>", { desc = "Save all and quit" })

-- ──────────────────────────────────────────────────────────────────────────────
-- <leader>s: Session 󱂬
-- ──────────────────────────────────────────────────────────────────────────────
if enabled(group, "session_manager") then
  map("n", "<leader>ss", "<CMD>SessionManager save_current_session<CR>", { desc = "Save session" })
  map("n", "<leader>sl", function() telescope_session_pick() end, { desc = "Load session" })
  map("n", "<leader>so", "<CMD>SessionManager load_last_session<CR>", { desc = "Open last session" })
  map("n", "<leader>sd", function() telescope_session_pick() end, { desc = "Delete session" })
end

-- ──────────────────────────────────────────────────────────────────────────────
-- <leader>t: Tab 󰓩
-- ──────────────────────────────────────────────────────────────────────────────
map("n", "<leader>tn", "<CMD>tabnew<CR>", { desc = "New tab" })
map("n", "<leader>tc", "<CMD>tabclose<CR>", { desc = "Close tab" })
map("n", "<leader>to", "<CMD>tabonly<CR>", { desc = "Close other tabs" })
map("n", "<leader>tp", "<CMD>tabprevious<CR>", { desc = "Previous tab" })

-- Terminal tools
if enabled(group, "toggleterm") then
  local git_root = "cd $(git rev-parse --show-toplevel 2>/dev/null) && clear"
  map("n", "<leader>tk", "<CMD>TermExec go_back=0 direction=float cmd='" .. git_root .. "&& tokei'<CR>", { desc = "Tokei" })
end

-- ──────────────────────────────────────────────────────────────────────────────
-- <leader>u: UI Toggles (core toggles provided by snacks.lua)
-- ──────────────────────────────────────────────────────────────────────────────
if enabled(group, "zen") then
  map("n", "<leader>uz", "<CMD>ZenMode<CR>", { desc = "Toggle zen mode" })
end

if enabled(group, "twilight") then
  map("n", "<leader>ut", "<CMD>Twilight<CR>", { desc = "Toggle twilight" })
end

if enabled(group, "notify") then
  map("n", "<leader>un", function() require("notify").dismiss() end, { desc = "Dismiss notifications" })
end

-- Colorscheme picker
map("n", "<leader>uc", "<CMD>LushColors<CR>", { desc = "Colorscheme picker" })

-- Config reload
map("n", "<leader>ur", "<CMD>LushReload<CR>", { desc = "Reload config (options/keymaps)" })

-- ──────────────────────────────────────────────────────────────────────────────
-- <leader>w: Window
-- ──────────────────────────────────────────────────────────────────────────────
map("n", "<leader>wv", "<CMD>vsplit<CR>", { desc = "Vertical split" })
map("n", "<leader>ws", "<CMD>split<CR>", { desc = "Horizontal split" })
map("n", "<leader>wc", "<CMD>close<CR>", { desc = "Close window" })
map("n", "<leader>wo", "<CMD>only<CR>", { desc = "Close other windows" })
map("n", "<leader>ww", "<C-w>p", { desc = "Switch to last window" })
map("n", "<leader>w=", "<C-w>=", { desc = "Equalize window sizes" })
map("n", "<leader>w+", "<CMD>resize +5<CR>", { desc = "Increase height" })
map("n", "<leader>w-", "<CMD>resize -5<CR>", { desc = "Decrease height" })
map("n", "<leader>w>", "<CMD>vertical resize +5<CR>", { desc = "Increase width" })
map("n", "<leader>w<", "<CMD>vertical resize -5<CR>", { desc = "Decrease width" })

-- ──────────────────────────────────────────────────────────────────────────────
-- <leader>x: Diagnostics 󰒡
-- ──────────────────────────────────────────────────────────────────────────────
if enabled(group, "trouble") then
  map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "All diagnostics" })
  map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer diagnostics" })
  map("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location list" })
  map("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix list" })
end

-- ══════════════════════════════════════════════════════════════════════════════
-- [6] Text Operations
-- ══════════════════════════════════════════════════════════════════════════════

-- Move lines/blocks with Alt+j/k
map("x", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("x", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- ══════════════════════════════════════════════════════════════════════════════
-- [7] Misc Mappings
-- ══════════════════════════════════════════════════════════════════════════════

-- Alpha dashboard
if enabled(group, "alpha") then
  map("n", "<leader>;", "<CMD>Alpha<CR>", { desc = "Dashboard" })
end

-- Hop
if enabled(group, "hop") then
  map("n", "<leader>j", "<CMD>HopWord<CR>", { desc = "Hop to word" })
end

-- Snacks scratch buffers
if enabled(group, "snacks") then
  map("n", "<leader>.", function() require("snacks").scratch() end, { desc = "Toggle scratch buffer" })
  map("n", "<leader>S", function() require("snacks").scratch.select() end, { desc = "Select scratch buffer" })
  map("n", "<leader>rn", function() require("snacks").rename.rename_file() end, { desc = "Rename file" })
end

-- Clear search highlight
map("n", "m", "<CMD>noh<CR>", { desc = "Clear search highlight" })

-- Which-key help
if enabled(group, "whichkey") then
  map("n", "<leader>?", function() require("which-key").show({ global = false }) end, { desc = "Show keymaps" })
end

-- Notify dismiss (ESC in normal/insert)
if enabled(group, "notify") then
  map("n", "<ESC>", "<CMD>lua require('notify').dismiss()<CR>", { desc = "Dismiss notifications" })
  map("i", "<ESC>", "<CMD>lua require('notify').dismiss()<CR><ESC>")
end

-- UFO folds
if enabled(group, "ufo") then
  map("n", "zR", "<CMD>lua require('ufo').openAllFolds()<CR>", { desc = "Open all folds" })
  map("n", "zM", "<CMD>lua require('ufo').closeAllFolds()<CR>", { desc = "Close all folds" })
end

-- Image paste
if enabled(group, "img_paste") then
  map("n", "<leader>p", "<CMD>PasteImage<CR>", { desc = "Paste clipboard image" })
end

-- Aerial (code map) - now under Find group via telescope
if enabled(group, "aerial") then
  map("n", "<leader>uA", "<CMD>AerialToggle<CR>", { desc = "Toggle aerial" })
end

-- ══════════════════════════════════════════════════════════════════════════════
-- [8] Terminal Mappings
-- ══════════════════════════════════════════════════════════════════════════════

-- Window switching from terminal
map("t", "<C-w>h", "<C-\\><C-n><C-w>h")
map("t", "<C-w>j", "<C-\\><C-n><C-w>j")
map("t", "<C-w>k", "<C-\\><C-n><C-w>k")
map("t", "<C-w>l", "<C-\\><C-n><C-w>l")

-- Direct Ctrl+hjkl navigation from terminal
map("t", "<C-h>", "<C-\\><C-n><C-w>h")
map("t", "<C-j>", "<C-\\><C-n><C-w>j")
map("t", "<C-k>", "<C-\\><C-n><C-w>k")
map("t", "<C-l>", "<C-\\><C-n><C-w>l")

-- ToggleTerm
if enabled(group, "toggleterm") then
  local git_root = "cd $(git rev-parse --show-toplevel 2>/dev/null) && clear"
  map("t", "<C-\\>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
  map("n", "<C-\\>", "<CMD>ToggleTerm go_back=0 cmd='" .. git_root .. "'<CR>", { desc = "Toggle terminal" })
end

-- ══════════════════════════════════════════════════════════════════════════════
-- [9] Diffview
-- ══════════════════════════════════════════════════════════════════════════════

if enabled(group, "diffview") then
  map("n", "<leader>go", function()
    local lib = require("diffview.lib")
    if lib.get_current_view() then
      vim.cmd.DiffviewClose()
    else
      vim.cmd.DiffviewOpen()
    end
  end, { desc = "Toggle diffview" })
  map("n", "<leader>gh", "<CMD>DiffviewFileHistory %<CR>", { desc = "File history" })
  map("n", "<leader>gH", "<CMD>DiffviewFileHistory<CR>", { desc = "Branch history" })
  map("v", "<leader>gh", ":DiffviewFileHistory<CR>", { desc = "Selection history" })
end

-- ══════════════════════════════════════════════════════════════════════════════
-- [10] Gitsigns on_attach Callback
-- ══════════════════════════════════════════════════════════════════════════════

if enabled(group, "gitsigns") then
  M.gitsigns = function()
    local gs = package.loaded.gitsigns

    -- Hunk navigation (bracket style) [c ]c
    map("n", "]c", function()
      if vim.wo.diff then return "]c" end
      vim.schedule(function() gs.next_hunk() end)
      return "<Ignore>"
    end, { expr = true, desc = "Next git hunk" })

    map("n", "[c", function()
      if vim.wo.diff then return "[c" end
      vim.schedule(function() gs.prev_hunk() end)
      return "<Ignore>"
    end, { expr = true, desc = "Previous git hunk" })

    -- Git operations under <leader>g
    map("n", "<leader>gs", gs.stage_hunk, { desc = "Stage hunk" })
    map("n", "<leader>gr", gs.reset_hunk, { desc = "Reset hunk" })
    map("n", "<leader>gS", gs.stage_buffer, { desc = "Stage buffer" })
    map("n", "<leader>gu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
    map("n", "<leader>gR", gs.reset_buffer, { desc = "Reset buffer" })
    map("n", "<leader>gp", gs.preview_hunk, { desc = "Preview hunk" })
    map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, { desc = "Blame line (full)" })
    map("n", "<leader>gd", gs.diffthis, { desc = "Diff this" })
    map("n", "<leader>gD", function() gs.diffthis("~") end, { desc = "Diff root" })
    map("n", "<leader>gT", gs.toggle_deleted, { desc = "Toggle deleted" })
    map("n", "<leader>gL", gs.toggle_current_line_blame, { desc = "Toggle line blame" })

    -- Visual mode stage/reset
    map("v", "<leader>gs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "Stage hunk" })
    map("v", "<leader>gr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "Reset hunk" })
  end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- [11] Insert/Command Mode Mappings
-- ══════════════════════════════════════════════════════════════════════════════

-- Insert mode navigation
map("i", "<C-d>", "<left><c-o>/[\"';)>}\\]]<cr><c-o><CMD>noh<cr><right>")
map("i", "<C-b>", "<C-o>0")
map("i", "<C-a>", "<C-o>A")

-- Command mode
map("c", "<C-p>", "<Up>")
map("c", "<C-n>", "<Down>")

return M
