return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'antoinemadec/FixCursorHold.nvim',
    'nvim-treesitter/nvim-treesitter',
    'rouge8/neotest-rust',
  },
  keys = {
    { '<leader>tt', function() require('neotest').run.run() end,                                     desc = 'Test: Run Nearest' },
    { '<leader>tT', function() require('neotest').run.run(vim.fn.expand('%')) end,                   desc = 'Test: Run File' },
    { '<leader>ta', function() require('neotest').run.run(vim.fn.getcwd()) end,                      desc = 'Test: Run All' },
    { '<leader>tl', function() require('neotest').run.run_last() end,                                desc = 'Test: Run Last' },
    { '<leader>td', function() require('neotest').run.run({ strategy = 'dap' }) end,                 desc = 'Test: Debug Nearest' },
    { '<leader>ts', function() require('neotest').summary.toggle() end,                              desc = 'Test: Toggle Summary' },
    { '<leader>to', function() require('neotest').output.open({ enter = true, auto_close = true }) end, desc = 'Test: Show Output' },
    { '<leader>tO', function() require('neotest').output_panel.toggle() end,                         desc = 'Test: Toggle Output Panel' },
    { '<leader>tS', function() require('neotest').run.stop() end,                                    desc = 'Test: Stop' },
  },
  config = function()
    require('neotest').setup({
      adapters = {
        require('neotest-rust')({
          args = { '--no-capture' },
        }),
      },
      status = { virtual_text = true },
      output = { open_on_run = false },
      summary = {
        mappings = {
          expand = { '<CR>', '<2-LeftMouse>' },
          expand_all = 'e',
          jumpto = 'i',
          output = 'o',
          run = 'r',
          short = 'O',
          stop = 'u',
        },
      },
    })
  end,
}
