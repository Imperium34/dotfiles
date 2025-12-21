return {
  -- 1. Load the Catppuccin theme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha", -- Or "frappe", "macchiato", "latte"
    },
  },

  -- 2. Disable the default tokyonight theme
  { "folke/tokyonight.nvim", lazy = true },
}
