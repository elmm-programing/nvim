return {
  {
    "mfussenegger/nvim-dap",
    lazy = true,
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
    },
    keys = {
      { "<leader>Db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      { "<leader>Dc", function() require("dap").continue() end, desc = "Debug continue" },
      { "<leader>Ds", function() require("dap").step_over() end, desc = "Step over" },
      { "<leader>Di", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>Do", function() require("dap").step_out() end, desc = "Step out" },
      { "<leader>DR", function() require("dap").restart() end, desc = "Debug restart" },
      { "<leader>Dx", function() require("dap").terminate() end, desc = "Debug terminate" },
      { "<leader>Du", function() require("dapui").toggle() end, desc = "Toggle debug UI" },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup({
        icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
        mappings = { edit = "e", expand = "<CR>", open = "o", remove = "d", repl = "r", toggle = "t" },
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.25 },
              { id = "breakpoints", size = 0.25 },
              { id = "stacks", size = 0.25 },
              { id = "watches", size = 0.25 },
            },
            size = 40,
            position = "left",
          },
          {
            elements = { { id = "repl", size = 0.5 }, { id = "console", size = 0.5 } },
            size = 10,
            position = "bottom",
          },
        },
        floating = { border = "rounded", max_height = nil, max_width = nil, mappings = { close = { "q", "<Esc>" } } },
      })

      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "●", texthl = "DapBreakpointCondition", linehl = "", numhl = "" })
      vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DapLogPoint", linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped", { text = "→", texthl = "DapStopped", linehl = "DapStoppedLine", numhl = "" })
    end,
  },

  {
    "leoluz/nvim-dap-go",
    ft = "go",
    dependencies = { "mfussenegger/nvim-dap" },
    opts = {
      delve = { path = vim.fn.stdpath("data") .. "/mason/packages/delve/dlv" },
    },
  },
}