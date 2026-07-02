return {
  {
    "windwp/nvim-ts-autotag",
    ft = { "vue", "html", "tsx", "jsx", "xml", "svelte" },
    opts = {
      opts = {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = false,
      },
      aliases = {
        ["vue"] = "html",
      },
    },
  },

  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
  },
}
