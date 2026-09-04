return {
  {
    "ray-x/go.nvim",
    ft = "go",
    dependencies = {
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      lsp_cfg = false, -- gopls is started from lua/config/plugins/lsp.lua
      lsp_codelens = false,
      max_len = 120,
      max_column = 120,
      auto_format = false, -- conform.nvim formats Go
      auto_save = false,
      fillstruct = "gopls",
      goimports = "gopls",
      gofmt = "gofumpt",
      test_runner = "go",
      test_flags = { "-v", "-count=1" },
      diagnostic = { hdlr = false },
    },
    config = function(_, opts)
      require("go").setup(opts)
    end,
  },
}
