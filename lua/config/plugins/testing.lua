return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "fredrikaverpil/neotest-golang",
      "nvim-neotest/neotest-jest",
      "marilari88/neotest-vitest",
      "rcasia/neotest-java",
    },
    opts = function()
      return {
        adapters = {
          require("neotest-golang")({
            runner = "go",
            args = { "-count=1", "-timeout=60s" },
          }),
          require("neotest-jest")({
            jestCommand = "jest",
            jestConfigFile = "jest.config.js",
            env = { CI = true },
            cwd = function()
              return vim.fn.getcwd()
            end,
          }),
          require("neotest-vitest")({
            cwd = function()
              return vim.fn.getcwd()
            end,
          }),
          require("neotest-java")({
            ignore_wrapper = false,
          }),
        },
        status = { virtual_text = true },
        output = { open_on_run = true },
        quickfix = {
          open = function()
            vim.cmd("copen")
          end,
        },
      }
    end,
    keys = {
      { "<leader>tt", function() require("neotest").run.run() end, desc = "Run nearest test" },
      { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run test file" },
      { "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Debug nearest test" },
      { "<leader>ts", function() require("neotest").run.stop() end, desc = "Stop test" },
      { "<leader>to", function() require("neotest").output.open({ enter = true }) end, desc = "Test output" },
      { "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Toggle output panel" },
      { "<leader>tS", function() require("neotest").summary.toggle() end, desc = "Test summary" },
      { "<leader>tW", function() require("neotest").watch.toggle(vim.fn.expand("%")) end, desc = "Toggle watch file" },
      { "<leader>tA", function() require("neotest").run.run({ suite = true }) end, desc = "Run all tests" },
      { "[t", function() require("neotest").jump.prev({ status = "failed" }) end, desc = "Prev failed test" },
      { "]t", function() require("neotest").jump.next({ status = "failed" }) end, desc = "Next failed test" },
    },
  },

  -- Coverage reporting
  {
    "andythigpen/nvim-coverage",
    dependencies = { "nvim-lua/plenary.nvim" },
    ft = { "go", "typescript", "javascript", "java" },
    opts = {
      commands = true,
      highlights = {
        covered = { fg = "#a6e3a1" },
        uncovered = { fg = "#f38ba8" },
        partial = { fg = "#f9e2af" },
      },
      signs = {
        covered = { hl = "CoverageCovered", text = "▎" },
        uncovered = { hl = "CoverageUncovered", text = "▎" },
        partial = { hl = "CoveragePartial", text = "▎" },
      },
      summary = {
        min_coverage = 80.0,
      },
    },
    keys = {
      { "<leader>tc", function() require("coverage").toggle() end, desc = "Toggle coverage" },
      { "<leader>tC", function() require("coverage").summary() end, desc = "Coverage summary" },
      { "<leader>tl", function() require("coverage").load(true) end, desc = "Load coverage (last)" },
    },
  },

  -- HTTP client (keys only in .http buffers so they do not clash with refactoring)
  {
    "mistweaverco/kulala.nvim",
    ft = "http",
    keys = {
      { "<leader>rr", function() require("kulala").run() end, ft = "http", desc = "Run HTTP request" },
      { "<leader>rl", function() require("kulala").replay() end, ft = "http", desc = "Replay last request" },
      { "<leader>rs", function() require("kulala").scratchpad() end, desc = "HTTP scratchpad" },
      { "<leader>re", function() require("kulala").set_selected_env() end, ft = "http", desc = "Select HTTP env" },
    },
    opts = {
      additional_curl_options = {},
      default_view = "body",
      split_direction = "vertical",
      default_env = "dev",
      debug = false,
      winbar = true,
    },
  },
}
