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
      "rouge8/neotest-rust",
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
          require("neotest-rust")({
            args = { "--no-capture" },
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
    ft = { "go", "typescript", "javascript", "java", "rust" },
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

  -- HTTP client. kulala.nvim's GitHub repo is private, so lazy cannot clone it.
  -- rest.nvim is public and sends requests with the system curl binary.
  -- Keys stay on .http buffers so they do not clash with refactoring.
  {
    "rest-nvim/rest.nvim",
    ft = { "http", "rest" },
    keys = {
      { "<leader>rr", "<cmd>Rest run<cr>", ft = "http", desc = "Run HTTP request" },
      { "<leader>rl", "<cmd>Rest last<cr>", ft = "http", desc = "Replay last request" },
      { "<leader>re", "<cmd>Rest env select<cr>", ft = "http", desc = "Select HTTP env" },
      {
        "<leader>rs",
        function()
          vim.cmd("enew")
          vim.bo.buftype = "nofile"
          vim.bo.bufhidden = "hide"
          vim.bo.swapfile = false
          vim.bo.filetype = "http"
          vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "### scratchpad",
            "GET https://httpbin.org/get HTTP/1.1",
            "accept: application/json",
            "",
          })
        end,
        desc = "HTTP scratchpad",
      },
    },
  },
}
