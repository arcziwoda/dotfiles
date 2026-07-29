-- Ctrl-h/j/k/l moves between Neovim splits and tmux panes interchangeably.
-- The tmux half is declared in ~/.config/tmux/tmux.conf; both sides are needed.
return {
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Go to left window" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Go to lower window" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Go to upper window" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Go to right window" },
    },
  },
}
