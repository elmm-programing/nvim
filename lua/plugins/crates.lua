return {
  'saecki/crates.nvim',
  event = { 'BufRead Cargo.toml' },
  opts = {
    completion = {
      crates = {
        enabled = true,
      },
    },
    lsp = {
      enabled = true,
      actions = true,
      completion = true,
      hover = true,
    },
  },
  config = function(_, opts)
    require('crates').setup(opts)

    vim.api.nvim_create_autocmd('BufRead', {
      group = vim.api.nvim_create_augroup('crates-nvim-keys', { clear = true }),
      pattern = 'Cargo.toml',
      callback = function(event)
        local map = function(keys, fn, desc)
          vim.keymap.set('n', keys, fn, { buffer = event.buf, desc = 'Crates: ' .. desc, silent = true })
        end
        local crates = require('crates')

        map('<leader>Rcv', crates.show_versions_popup, 'Show Versions')
        map('<leader>Rcf', crates.show_features_popup, 'Show Features')
        map('<leader>Rcd', crates.show_dependencies_popup, 'Show Dependencies')
        map('<leader>Rcu', crates.update_crate, 'Update Crate')
        map('<leader>RcU', crates.upgrade_crate, 'Upgrade Crate')
        map('<leader>Rca', crates.update_all_crates, 'Update All')
        map('<leader>RcA', crates.upgrade_all_crates, 'Upgrade All')
        map('<leader>Rco', crates.open_documentation, 'Open Docs.rs')
        map('<leader>Rcc', crates.open_crates_io, 'Open Crates.io')
        map('<leader>Rch', crates.open_homepage, 'Open Homepage')
        map('<leader>Rcr', crates.open_repository, 'Open Repository')

        map('K', function()
          if crates.popup_available() then
            crates.show_popup()
          else
            vim.lsp.buf.hover()
          end
        end, 'Show Crate Info')
      end,
    })
  end,
}
