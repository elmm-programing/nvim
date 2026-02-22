return {
  'nvim-pack/nvim-spectre',
  dependencies = { 'nvim-lua/plenary.nvim' },
  keys = {
    { '<leader>rs', '<cmd>lua require("spectre").toggle()<CR>', desc = 'Toggle Spectre ([R]eplace [S]earch)' },
    { '<leader>rw', '<cmd>lua require("spectre").open_visual({select_word=true})<CR>', desc = '[R]eplace current [W]ord' },
    { '<leader>rw', '<esc><cmd>lua require("spectre").open_visual()<CR>', mode = 'v', desc = '[R]eplace current [W]ord (Visual)' },
    { '<leader>rf', '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>', desc = '[R]eplace in current [F]ile' },
  },
  config = function()
    require('spectre').setup {
      color_devicons = true,
      open_cmd = 'vnew',
      live_update = false, -- auto execute search again when you write any file in vim
      line_sep_start = '-----------------------------------------',
      result_padding = '¦  ',
      line_sep       = '-----------------------------------------',
    }
  end,
}
