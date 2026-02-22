return {
  -- Add Vue tools to mason
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        'vue-language-server',       -- LSP for Vue
        'prettier',    -- Formatter
      })
    end,
  },

  -- Configure Vue LSP
  {
    'neovim/nvim-lspconfig',
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.vue_ls = {}
    end,
  },

  -- Configure Vue Formatter
  {
    'stevearc/conform.nvim',
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.vue = { 'prettier' }
    end,
  },

  -- Ensure Vue Treesitter parser is installed
  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'vue', 'css', 'scss' })
    end,
  },
}
