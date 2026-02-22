return {
  -- Add TypeScript tools to mason
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        'typescript-language-server',       -- LSP (TypeScript/JavaScript)
        'prettier',    -- Formatter
        'js-debug-adapter', -- Debugger for JS/TS/Vue
      })
    end,
  },

  -- Configure TypeScript LSP
  {
    'neovim/nvim-lspconfig',
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.ts_ls = {
        init_options = {
          plugins = {
            {
              name = '@vue/typescript-plugin',
              location = vim.fn.stdpath('data') .. '/mason/packages/vue-language-server/node_modules/@vue/language-server',
              languages = { 'vue' },
            },
          },
        },
        filetypes = {
          'javascript',
          'javascriptreact',
          'javascript.jsx',
          'typescript',
          'typescriptreact',
          'typescript.tsx',
          'vue',
        },
      }
    end,
  },

  -- Configure TypeScript Formatter
  {
    'stevearc/conform.nvim',
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.javascript = { 'prettier' }
      opts.formatters_by_ft.typescript = { 'prettier' }
      opts.formatters_by_ft.javascriptreact = { 'prettier' }
      opts.formatters_by_ft.typescriptreact = { 'prettier' }
    end,
  },

  -- Ensure TypeScript Treesitter parsers are installed
  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'javascript', 'typescript', 'tsx' })
    end,
  },
}
