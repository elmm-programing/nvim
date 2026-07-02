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
      max_len = 120,
      max_column = 120,
      auto_format = true,
      auto_save = true,
      fillstruct = "gopls",
      goimports = "gopls",
      gofmt = "gofumpt",
      test_runner = "go",
      test_flags = { "-v", "-count=1" },
      lint_style = "revive",
      diagnostic = { hdlr = false },
    },
    config = function(_, opts)
      require("go").setup(opts)
    end,
  },

  {
    "nvim-neotest/neotest",
    ft = "go",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      {
        "fredrikaverpil/neotest-golang",
        dependencies = { "leoluz/nvim-dap-go" },
      },
    },
    opts = function()
      return {
        adapters = {
          ["neotest-golang"] = {
            runner = "go",
          },
        },
      }
    end,
    keys = {
      { "<leader>tt", function() require("neotest").run.run() end, desc = "Run nearest test" },
      { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run test file" },
      { "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Debug nearest test" },
      { "<leader>ts", function() require("neotest").run.stop() end, desc = "Stop test" },
      { "<leader>to", function() require("neotest").output.open({ enter = true }) end, desc = "Test output" },
      { "<leader>tS", function() require("neotest").summary.toggle() end, desc = "Test summary" },
      { "[t", function() require("neotest").jump.prev({ status = "failed" }) end, desc = "Prev failed test" },
      { "]t", function() require("neotest").jump.next({ status = "failed" }) end, desc = "Next failed test" },
    },
  },
}