return {
  -- Add Java tools to mason
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        'jdtls',       -- LSP for Java
        'google-java-format', -- Formatter
        'vscode-spring-boot-tools', -- Spring Boot LSP
        'java-debug-adapter', -- Debug adapter for nvim-dap
        'java-test',   -- Java test runner
      })
    end,
  },
  
  -- The industry standard java configuration plugin
  {
    'mfussenegger/nvim-jdtls',
    lazy = true, -- we will load this in ftplugin/java.lua
  },

  -- Configure Spring Boot LSP (JDTLS will be configured in ftplugin/java.lua)
  {
    'neovim/nvim-lspconfig',
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      -- Framework-specific JDTLS extensions are handled in ftplugin/java.lua
    end,
  },

  -- Configure Java Formatter
  {
    'stevearc/conform.nvim',
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.java = { 'google-java-format' }
    end,
  },

  -- Ensure Java Treesitter parser is installed
  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'java' })
    end,
  },
}
