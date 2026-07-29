-- Catppuccin Macchiato, matching the terminal and tmux.
--
-- Naming trap: since catppuccin/nvim v2.0.0 the plugin's own colourscheme is
-- registered as "catppuccin-nvim", because Neovim 0.12 ships an unrelated
-- built-in scheme called "catppuccin". LazyVim's core maps `colorscheme =
-- "catppuccin"` onto the plugin for us, so set it through LazyVim's opts;
-- if you ever call :colorscheme by hand, use catppuccin-nvim.
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      flavour = "macchiato",
      -- The terminal is translucent (background-opacity 0.9), so let it
      -- through here too. `float.solid = false` keeps popups readable.
      transparent_background = true,
      float = { transparent = true, solid = false },
      integrations = {
        blink_cmp = true,
        snacks = true,
        neotest = true,
        which_key = true,
        mason = true,
        dap = true,
        dap_ui = true,
        lsp_trouble = true,
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "catppuccin" },
  },
}
