local dap = require("dap")

if not dap.adapters["pwa-chrome"] then
  require("dap").adapters["pwa-chrome"] = {
    type = "server",
    host = "localhost",
    port = "${port}",
    executable = {
      command = "node",
      args = {
        -- Make sure this path is correct for js-debug-adapter
        LazyVim.get_pkg_path("js-debug-adapter", "/js-debug/src/dapDebugServer.js"),
        "${port}",
      },
    },
  }
end

if not dap.adapters["pwa-node"] then
  require("dap").adapters["pwa-node"] = {
    type = "server",
    host = "localhost",
    port = "${port}",
    executable = {
      command = "node",
      -- 💀 Make sure to update this path to point to your installation
      args = {
        LazyVim.get_pkg_path("js-debug-adapter", "/js-debug/src/dapDebugServer.js"),
        "${port}",
      },
    },
  }
end
if not dap.adapters["node"] then
  dap.adapters["node"] = function(cb, config)
    if config.type == "node" then
      config.type = "pwa-node"
    end
    local nativeAdapter = dap.adapters["pwa-node"]
    if type(nativeAdapter) == "function" then
      nativeAdapter(cb, config)
    else
      cb(nativeAdapter)
    end
  end
end

local js_filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact", "vue" }

local vscode = require("dap.ext.vscode")
vscode.type_to_filetypes["node"] = js_filetypes
vscode.type_to_filetypes["pwa-node"] = js_filetypes

for _, language in ipairs(js_filetypes) do
  if not dap.configurations[language] then
    dap.configurations[language] = {
      {
        type = "pwa-node",
        request = "launch",
        name = "Launch file",
        program = "${file}",
        cwd = "${workspaceFolder}",
        outFiles = { "${workspaceFolder}/dist/**/*.js" },
      },
      {
        type = "pwa-node",
        request = "attach",
        name = "Attach",
        processId = require("dap.utils").pick_process,
        cwd = "${workspaceFolder}",
      },
      {
        name = "server: Nuxt",
        type = "pwa-node",
        request = "launch",
        cwd = "${workspaceFolder}",
        runtimeExecutable = "npm",
        runtimeArgs = { "run", "dev" },
        console = "integratedTerminal",
      },
      {
        type = "chrome",
        name = "Launch Chrome to debug client",
        request = "launch",
        url = function()
          -- Corrected: Remove the invalid 'url' complete argument
          return vim.fn.input("Enter URL to debug: ", "http://localhost:3000")
        end,
        sourceMaps = true,
        protocol = "inspector",
        port = 9222,
        webRoot = "${workspaceFolder}",
        runtimeExecutable = "/usr/bin/brave-browser-beta",
      },
    }
  end
end
