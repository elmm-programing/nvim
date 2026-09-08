-- Phase 2: guaranteed formatters, linters, debuggers via Mason
return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = {
      "williamboman/mason.nvim",
    },
    event = "VeryLazy",
    opts = {
      ensure_installed = {
        -- Go
        "gofumpt",
        "goimports",
        "delve",
        "golangci-lint",
        -- Frontend
        "prettier",
        "eslint_d",
        -- Java
        "google-java-format",
        "java-debug-adapter",
        "java-test",
        -- General
        "stylua",
      },
      auto_update = false,
      run_on_start = true,
      start_delay = 3000,
      debounce_hours = 24,
    },
  },
}
