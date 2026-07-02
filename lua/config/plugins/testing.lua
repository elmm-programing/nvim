return {
  -- Testing framework for multiple languages
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      -- Go testing
      {
        "fredrikaverpil/neotest-golang",
        dependencies = { "leoluz/nvim-dap-go" },
        ft = "go",
      },
      -- TypeScript/JavaScript testing
      {
        "nvim-neotest/neotest-jest",
        ft = { "typescript", "javascript", "typescriptreact", "javascriptreact", "vue" },
      },
      -- Vitest support
      {
        "marilari88/neotest-vitest",
        ft = { "typescript", "javascript", "typescriptreact", "javascriptreact", "vue" },
      },
      -- Java testing
      {
        "rcasia/neotest-java",
        ft = "java",
      },
    },
    opts = function()
      return {
        adapters = {
          ["neotest-golang"] = {
            runner = "go",
            args = { "-count=1", "-timeout=60s" },
          },
          ["neotest-jest"] = {
            jestCommand = "jest",
            jestConfigFile = "jest.config.js",
            env = { CI = true },
            cwd = function(path)
              return vim.fn.getcwd()
            end,
          },
          ["neotest-vitest"] = {
            vitestCommand = "vitest",
            vitestConfigFile = "vitest.config.ts",
            cwd = function(path)
              return vim.fn.getcwd()
            end,
          },
          ["neotest-java"] = {
            ignore_wrapper = false,
          },
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

  -- REST client for API testing
  {
    "rest-nvim/rest.nvim",
    version = "*",
    ft = "http",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>rr", "<cmd>Rest run<cr>", desc = "Run request under cursor" },
      { "<leader>rl", "<cmd>Rest run last<cr>", desc = "Run last request" },
      { "<leader>rp", "<cmd>Rest preview<cr>", desc = "Preview request" },
    },
    opts = {
      result = {
        behavior = {
          decode_url = true,
          show_info = {
            url = true,
            headers = true,
            http_info = true,
            curl_command = true,
          },
          statistics = {
            enable = true,
            timeout = 5000,
          },
          formatters = {
            json = "jq",
            html = function(body)
              return vim.fn.system({ "tidy", "-i", "-q", "-" }, body)
            end,
          },
        },
        keybinds = {
          buffer_local = true,
        },
      },
      highlight = {
        enable = true,
        timeout = 150,
      },
      jump = {
        behavior = "closest",
        request = {
          above = "previous",
          below = "next",
        },
      },
    },
  },

  -- HTTP syntax highlighting
  {
    "mistweaverco/kulala.nvim",
    ft = "http",
    keys = {
      { "<leader>rs", function() require("kulala").scratchpad() end, desc = "Open scratchpad" },
      { "<leader>re", function() require("kulala").set_selected_env() end, desc = "Select env" },
    },
    opts = {
      additional_curl_options = {},
      -- ↓ Send mode (“external” or “body”)
      -- "external": open results in external viewer
      -- "body": open results in split window
      default_view = "body",
      -- split direction
      split_direction = "vertical",
      -- default env
      default_env = "dev",
      -- enable/disable debug mode
      debug = false,
      -- highlight requests with icon
      icons = {
        inlay = {
          loading = "⏳",
          done = "✅",
          error = "❌",
        },
        lualine = "🐼",
      },
      -- enable/disable winbar
      winbar = true,
      -- default show variable info in request line
      default_show_info = true,
      -- enable/disable request folding
      enable_folding = false,
      -- ↓ Request display options
      request = {
        -- enable/disable request title
        show_title = true,
        -- enable/disable request headers
        show_headers = true,
        -- enable/disable request body
        show_body = true,
        -- enable/disable request URL
        show_url = true,
        -- enable/disable request method
        show_method = true,
      },
      -- ↓ Response display options
      response = {
        -- enable/disable response headers
        show_headers = true,
        -- enable/disable response body
        show_body = true,
        -- enable/disable response status
        show_status = true,
      },
    },
  },
}
