local dap = require("dap")

dap.configurations.java = {
  {
    type = "java",
    request = "attach",
    name = "Debug (Attach) - Remote",
    hostName = function()
      return vim.fn.input("Enter hostname (default 127.0.0.1): ", "127.0.0.1")
    end,
    port = function()
      local port_str = vim.fn.input("Enter port (default 5005): ", "5005")
      return tonumber(port_str) or 5005 -- Ensure it's a number, default if invalid
    end,
  },
}
