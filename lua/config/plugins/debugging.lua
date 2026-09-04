local function mason_pkg(path)
  return vim.fn.stdpath("data") .. "/mason/packages/" .. path
end

local function browser_executable()
  for _, name in ipairs({
    "brave-browser-beta",
    "brave-browser",
    "google-chrome-stable",
    "google-chrome",
    "chromium",
    "chromium-browser",
  }) do
    if vim.fn.executable(name) == 1 then
      return name
    end
  end
end

local function has_config(configs, name)
  for _, config in ipairs(configs or {}) do
    if config.name == name then
      return true
    end
  end
  return false
end

local function add_config(language, config)
  local dap = require("dap")
  dap.configurations[language] = dap.configurations[language] or {}
  if not has_config(dap.configurations[language], config.name) then
    table.insert(dap.configurations[language], config)
  end
end

local function setup_js_dap()
  local dap = require("dap")
  local debugger = mason_pkg("js-debug-adapter/js-debug/src/dapDebugServer.js")
  if vim.fn.filereadable(debugger) == 0 then
    return
  end

  if not dap.adapters["pwa-node"] then
    dap.adapters["pwa-node"] = {
      type = "server",
      host = "localhost",
      port = "${port}",
      executable = { command = "node", args = { debugger, "${port}" } },
    }
  end
  if not dap.adapters["pwa-chrome"] then
    dap.adapters["pwa-chrome"] = {
      type = "server",
      host = "localhost",
      port = "${port}",
      executable = { command = "node", args = { debugger, "${port}" } },
    }
  end

  local chrome = {
    type = "pwa-chrome",
    name = "Launch Chrome to debug client",
    request = "launch",
    url = function()
      return vim.fn.input("Enter URL to debug: ", "http://localhost:3000")
    end,
    sourceMaps = true,
    webRoot = "${workspaceFolder}",
  }
  local browser = browser_executable()
  if browser then
    chrome.runtimeExecutable = browser
  end

  for _, language in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact", "vue" }) do
    add_config(language, {
      type = "pwa-node",
      request = "launch",
      name = "Launch file",
      program = "${file}",
      cwd = "${workspaceFolder}",
      outFiles = { "${workspaceFolder}/dist/**/*.js" },
    })
    add_config(language, {
      type = "pwa-node",
      request = "attach",
      name = "Attach",
      processId = require("dap.utils").pick_process,
      cwd = "${workspaceFolder}",
    })
    add_config(language, {
      name = "server: Nuxt",
      type = "pwa-node",
      request = "launch",
      cwd = "${workspaceFolder}",
      runtimeExecutable = "npm",
      runtimeArgs = { "run", "dev" },
      console = "integratedTerminal",
    })
    add_config(language, vim.deepcopy(chrome))
  end
end

local function setup_java_dap()
  require("dap").configurations.java = {
    {
      type = "java",
      request = "attach",
      name = "Debug (Attach) - Remote",
      hostName = function()
        return vim.fn.input("Enter hostname (default 127.0.0.1): ", "127.0.0.1")
      end,
      port = function()
        return tonumber(vim.fn.input("Enter port (default 5005): ", "5005")) or 5005
      end,
    },
  }
end

return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        "js-debug-adapter",
        "java-debug-adapter",
        "java-test",
        "delve",
        "gofumpt",
        "goimports",
        "prettier",
        "stylua",
        "google-java-format",
        "vue-language-server",
        "eslint_d",
      },
    },
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      automatic_installation = true,
      ensure_installed = { "delve" },
    },
  },
  {
    "mfussenegger/nvim-dap",
    lazy = true,
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
      "jay-babu/mason-nvim-dap.nvim",
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
      pcall(require("nvim-dap-virtual-text").setup)

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
        floating = { border = "rounded", mappings = { close = { "q", "<Esc>" } } },
      })

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapStopped", { text = "→", texthl = "DiagnosticWarn", linehl = "Visual" })

      setup_js_dap()
      setup_java_dap()
    end,
  },
  {
    "leoluz/nvim-dap-go",
    ft = "go",
    dependencies = { "mfussenegger/nvim-dap" },
    opts = {
      delve = { path = mason_pkg("delve/dlv") },
    },
  },
}
