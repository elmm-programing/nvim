return {
  -- Add ALL Golang tools to mason
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        'ast-grep',
        'crlfmt',
        'delve',
        'djlint',
        'gci',
        'go-debug-adapter',
        'gofumpt',
        'goimports',
        'goimports-reviser',
        'golangci-lint',
        'golangci-lint-langserver',
        'golines',
        'gomodifytags',
        'gopls',
        'gotests',
        'gotestsum',
        'iferr',
        'impl',
        'json-to-struct',
        'nilaway',
        'revive',
        'sonarlint-language-server',
        'staticcheck',
        'templ',
        'trivy',
      })
    end,
  },

  -- Configure Golang & Templ LSPs
  {
    'neovim/nvim-lspconfig',
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      
      opts.servers.gopls = {
        settings = {
          gopls = {
            gofumpt = true,
            usePlaceholders = true,
            analyses = {
              unusedparams = true,
            },
            -- Tell gopls to use the statically installed staticcheck
            staticcheck = true,
          },
        },
      }
      
      -- Hook up the dedicated golangci-lint LSP
      opts.servers.golangci_lint_ls = {}
      
      -- Hook up the Templ LSP for Go templating
      opts.servers.templ = {}
    end,
  },

  -- Configure Golang Formatters
  {
    'stevearc/conform.nvim',
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      -- Run goimports, then golines (to wrap long lines), then gofumpt (for strict formatting)
      opts.formatters_by_ft.go = { 'goimports', 'golines', 'gofumpt' }
      -- Also format templ files if desired
      opts.formatters_by_ft.templ = { 'prettier' } 
    end,
  },

  -- Ensure Golang and Templ Treesitter parsers are installed
  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'go', 'gomod', 'gowork', 'gosum', 'templ' })
    end,
  },
}
