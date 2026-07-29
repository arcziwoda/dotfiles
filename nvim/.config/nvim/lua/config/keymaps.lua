-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Alt-hjkl moves between splits and tmux panes in one motion. Ctrl-hjkl is
-- deliberately left free so that Ctrl-L keeps clearing the screen in a shell.
map("n", "<M-h>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Go to left window/pane" })
map("n", "<M-j>", "<cmd>TmuxNavigateDown<cr>", { desc = "Go to lower window/pane" })
map("n", "<M-k>", "<cmd>TmuxNavigateUp<cr>", { desc = "Go to upper window/pane" })
map("n", "<M-l>", "<cmd>TmuxNavigateRight<cr>", { desc = "Go to right window/pane" })

-- That takes over LazyVim's <A-j>/<A-k> "move line" bindings, so shift those up
-- one modifier rather than losing them.
map("n", "<M-J>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<M-K>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<M-J>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<M-K>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<M-J>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<M-K>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })
