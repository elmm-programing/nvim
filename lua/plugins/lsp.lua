return {
  {
    -- Main LSP Configuration
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'mason-org/mason.nvim', opts = {} },
      {
        'WhoIsSethDaniel/mason-tool-installer.nvim',
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, {
            'lua-language-server',
            'stylua',
          })
        end,
      },
      { 'j-hui/fidget.nvim', opts = {} },
      'saghen/blink.cmp',
    },
    config = function(_, opts)
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          map('<leader>cl', '<cmd>LspInfo<cr>', 'Lsp Info')
          map('gd', vim.lsp.buf.definition, 'Goto Definition')
          map('gr', vim.lsp.buf.references, 'References')
          map('gI', vim.lsp.buf.implementation, 'Goto Implementation')
          map('gy', vim.lsp.buf.type_definition, 'Goto T[y]pe Definition')
          map('gD', vim.lsp.buf.declaration, 'Goto Declaration')
          map('K', vim.lsp.buf.hover, 'Hover')
          map('gK', vim.lsp.buf.signature_help, 'Signature Help')
          map('<c-k>', vim.lsp.buf.signature_help, 'Signature Help', 'i')
          map('<leader>ca', vim.lsp.buf.code_action, 'Code Action', { 'n', 'x' })
          map('<leader>cc', vim.lsp.codelens.run, 'Run Codelens', { 'n', 'x' })
          map('<leader>cC', vim.lsp.codelens.refresh, 'Refresh & Display Codelens')
          map('<leader>cR', function() Snacks.rename.rename_file() end, 'Rename File') -- Optional: if using snacks.nvim
          map('<leader>cr', vim.lsp.buf.rename, 'Rename')
          map('<leader>cA', function()
            vim.lsp.buf.code_action({
              context = {
                only = {
                  "source",
                },
                diagnostics = {},
              },
            })
          end, 'Source Action')
          
          -- Reference jumping
          map(']]', function() vim.lsp.buf.references() end, 'Next Reference')
          map('[[', function() vim.lsp.buf.references() end, 'Prev Reference')
          map('<a-n>', function() vim.lsp.buf.references() end, 'Next Reference')
          map('<a-p>', function() vim.lsp.buf.references() end, 'Prev Reference')

          -- Telescope integrations (assuming telescope is present based on earlier config)
          map('<leader>ss', require('telescope.builtin').lsp_document_symbols, 'LSP Symbols')
          map('<leader>sS', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'LSP Workspace Symbols')
          map('gai', require('telescope.builtin').lsp_incoming_calls, 'C[a]lls Incoming')
          map('gao', require('telescope.builtin').lsp_outgoing_calls, 'C[a]lls Outgoing')

          -- Diagnostic navigation
          map(']d', vim.diagnostic.goto_next, 'Next Diagnostic')
          map('[d', vim.diagnostic.goto_prev, 'Prev Diagnostic')
          map('gl', vim.diagnostic.open_float, 'Hover Diagnostic')

          -- Formatting and Workspace
          map('<leader>cf', function() vim.lsp.buf.format { async = true } end, 'Format Code')
          map('<leader>cwa', vim.lsp.buf.add_workspace_folder, 'Workspace Add Folder')
          map('<leader>cwr', vim.lsp.buf.remove_workspace_folder, 'Workspace Remove Folder')
          map('<leader>cwl', function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end, 'Workspace List Folders')

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method('textDocument/documentHighlight', event.buf) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          if client and client:supports_method('textDocument/inlayHint', event.buf) then
            map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      local capabilities = require('blink.cmp').get_lsp_capabilities()

      -- Setup mason so it can provide third party binaries
      require('mason').setup()

      -- Merge the base servers with any servers passed in via opts (from lang/*.lua)
      local servers = vim.tbl_deep_extend('force', {
        lua_ls = {
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
            },
          },
        },
      }, opts.servers or {})

      -- Provide the servers directly to lspconfig
      -- Note: `mason-tool-installer` handles installing 'lua-language-server' in another block
      -- so we don't automatically extract `vim.tbl_keys(servers)` anymore.
      
      -- Load blink.cmp capabilities
      local capabilities = require('blink.cmp').get_lsp_capabilities()

      for name, server in pairs(servers) do
        server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
        vim.lsp.config(name, server)
        vim.lsp.enable(name)
      end
    end,
  },
}
