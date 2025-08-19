return {
  {
    "nvim-pack/nvim-spectre",
    dependencies = {
      {
        "nvim-lua/plenary.nvim",
      },
    },
    keys = {

      {
        "<leader>rs",
        "<cmd> Spectre<CR>",
        desc = "Toggle Spectre",
      },
      {
        "<leader>rw",
        '<cmd>lua require("spectre").open_visual({select_word=true})<CR>',
        desc = "Search current word",
      },
      {
        "<leader>ri",
        '<esc><cmd>lua require("spectre").open_visual()<CR>',
        mode = "v",
        desc = "Search current word",
      },
      {
        "<leader>rp",
        '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>',
        desc = "Search on current file",
      },
    },
  },
}
