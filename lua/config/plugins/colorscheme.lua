return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = true,
      styles = {
        comments = { "italic" },
        keywords = { "italic" },
      },
      integrations = {
        blink_cmp = true,
        gitsigns = true,
        mason = true,
        neotree = true,
        snacks = true,
        telescope = true,
        which_key = true,
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end,
  },
}
