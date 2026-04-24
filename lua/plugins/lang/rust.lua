return {
  -- Add Rust tools to mason
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        'rust-analyzer',
        'codelldb',
      })
    end,
  },

  -- Rust IDE layer. Owns rust_analyzer lifecycle and wires DAP automatically.
  -- Do NOT configure rust_analyzer via nvim-lspconfig when using this plugin.
  {
    'mrcjkb/rustaceanvim',
    version = '^6',
    lazy = false,
    init = function()
      local mason_path = vim.fn.stdpath('data') .. '/mason'
      local codelldb_path = mason_path .. '/packages/codelldb/extension/adapter/codelldb'
      local liblldb_ext = vim.fn.has('mac') == 1 and 'liblldb.dylib' or 'liblldb.so'
      local liblldb_path = mason_path .. '/packages/codelldb/extension/lldb/lib/' .. liblldb_ext

      vim.g.rustaceanvim = function()
        local ok_blink, blink = pcall(require, 'blink.cmp')
        local capabilities = ok_blink and blink.get_lsp_capabilities() or {}

        local dap = nil
        local ok_cfg, cfg = pcall(require, 'rustaceanvim.config')
        if ok_cfg and vim.fn.filereadable(codelldb_path) == 1 then
          dap = { adapter = cfg.get_codelldb_adapter(codelldb_path, liblldb_path) }
        end

        return {
          tools = {
            float_win_config = { border = 'rounded' },
            hover_actions = { replace_builtin_hover = true },
          },
          server = {
            capabilities = capabilities,
            default_settings = {
              ['rust-analyzer'] = {
                cargo = {
                  allFeatures = true,
                  loadOutDirsFromCheck = true,
                  runBuildScripts = true,
                },
                checkOnSave = true,
                check = {
                  command = 'clippy',
                  extraArgs = { '--no-deps' },
                  allFeatures = true,
                },
                procMacro = {
                  enable = true,
                },
                inlayHints = {
                  bindingModeHints = { enable = true },
                  chainingHints = { enable = true },
                  closingBraceHints = { enable = true, minLines = 25 },
                  closureReturnTypeHints = { enable = 'never' },
                  lifetimeElisionHints = { enable = 'never', useParameterNames = false },
                  parameterHints = { enable = true },
                  reborrowHints = { enable = 'never' },
                  renderColons = true,
                  typeHints = { enable = true, hideClosureInitialization = false, hideNamedConstructor = false },
                },
              },
            },
          },
          dap = dap,
        }
      end

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'rust',
        group = vim.api.nvim_create_augroup('rustaceanvim-keys', { clear = true }),
        callback = function(event)
          local map = function(keys, cmd, desc)
            vim.keymap.set('n', keys, cmd, { buffer = event.buf, desc = 'Rust: ' .. desc, silent = true })
          end
          map('<leader>Rr', '<cmd>RustLsp runnables<cr>', 'Runnables')
          map('<leader>RR', '<cmd>RustLsp runnables last<cr>', 'Run Last')
          map('<leader>Rd', '<cmd>RustLsp debuggables<cr>', 'Debuggables')
          map('<leader>RD', '<cmd>RustLsp debuggables last<cr>', 'Debug Last')
          map('<leader>Re', '<cmd>RustLsp expandMacro<cr>', 'Expand Macro')
          map('<leader>RE', '<cmd>RustLsp explainError<cr>', 'Explain Error')
          map('<leader>Rm', '<cmd>RustLsp parentModule<cr>', 'Parent Module')
          map('<leader>Ro', '<cmd>RustLsp openDocs<cr>', 'Open Docs.rs')
          map('<leader>Rp', '<cmd>RustLsp rebuildProcMacros<cr>', 'Rebuild Proc Macros')
          map('<leader>Rh', '<cmd>RustLsp hover actions<cr>', 'Hover Actions')
          map('<leader>Rj', '<cmd>RustLsp joinLines<cr>', 'Join Lines')
          map('<leader>Rg', '<cmd>RustLsp crateGraph<cr>', 'Crate Graph')
          map('K', '<cmd>RustLsp hover actions<cr>', 'Hover Actions')
        end,
      })
    end,
  },

  -- Configure Rust formatter
  {
    'stevearc/conform.nvim',
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.rust = { 'rustfmt' }
    end,
  },

  -- Ensure Rust treesitter parsers are installed
  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'rust', 'ron', 'toml' })
    end,
  },
}
