-- Alt-h/j/k/l moves between Neovim splits and tmux panes interchangeably.
-- The tmux half is declared in ~/.config/tmux/tmux.conf; both sides are needed.
--
-- The keymaps live in lua/config/keymaps.lua, not here: LazyVim binds <A-j> and
-- <A-k> to "move line" and its defaults load after lazy registers plugin keys,
-- so declaring them here would lose the race. Only the lazy-load trigger stays.
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
  },
}
