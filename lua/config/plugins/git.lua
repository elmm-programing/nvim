return {
  {
    "lewis6991/gitsigns.nvim",
    -- Newer gitsigns calls vim.validate with a string, which errors on Neovim
    -- before 0.11: "opt: expected table, got string".
    version = "2.1.0",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "▁" },
        topdelete = { text = "▔" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      signcolumn = true,
      numhl = true,
      watch_gitdir = { follow_files = true },
      current_line_blame = true,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 300,
      },
      current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",
      on_attach = function(bufnr)
        local gs = require("gitsigns")

        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end

        map("n", "<leader>hu", gs.undo_stage_hunk, "Undo stage hunk")
        map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
        map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame line")
        map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line")
        map("n", "<leader>gB", function()
          if gs.blame then
            gs.blame()
          else
            vim.cmd("Gitsigns blame")
          end
        end, "Blame buffer")
        map("n", "<leader>hd", gs.diffthis, "Diff this")
        map("n", "<leader>hD", function() gs.diffthis("~") end, "Diff this ~")
        map("n", "]h", function() gs.nav_hunk("next") end, "Next hunk")
        map("n", "[h", function() gs.nav_hunk("prev") end, "Previous hunk")
        map({ "n", "v" }, "<leader>hs", ":Gitsigns stage_hunk<CR>", "Stage hunk")
        map({ "n", "v" }, "<leader>gh", function()
          gs.stage_hunk()
        end, "Stage or unstage hunk")
        map("n", "<leader>gs", function()
          local hunks = gs.get_hunks(bufnr)
          if hunks and #hunks > 0 then
            gs.stage_buffer()
          else
            gs.reset_buffer_index(bufnr)
          end
        end, "Stage or unstage buffer")
        map({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>", "Reset hunk")
      end,
    },
  },

  {
    "NeogitOrg/neogit",
    cmd = "Neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "nvim-telescope/telescope.nvim",
    },
    keys = {
      { "<leader>gg", "<cmd>Neogit<CR>", desc = "Open Neogit" },
      { "<leader>gc", "<cmd>Neogit commit<CR>", desc = "Neogit commit" },
    },
    opts = {
      integrations = { diffview = true, telescope = true },
      signs = {
        item = { ">", "" },
        section = { ">", "" },
      },
    },
  },

  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    keys = {
      { "<leader>gv", "<cmd>DiffviewOpen<CR>", desc = "Diff view" },
      { "<leader>gH", "<cmd>DiffviewFileHistory %<CR>", desc = "File history" },
    },
  },

  {
    "echasnovski/mini.diff",
    event = { "BufReadPre", "BufNewFile" },
    keys = {
      {
        "<leader>gd",
        function()
          require("mini.diff").toggle_overlay(0)
        end,
        desc = "Toggle diff overlay",
      },
    },
    opts = {
      view = {
        style = "sign",
        signs = { add = "", change = "", delete = "" },
      },
      mappings = {
        apply = "",
        reset = "",
        textobject = "",
        goto_first = "",
        goto_prev = "",
        goto_next = "",
        goto_last = "",
      },
    },
  },

  {
    "ruifm/gitlinker.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      {
        "<leader>gy",
        function()
          require("gitlinker").get_buf_range_url("n")
        end,
        mode = "n",
        desc = "Copy git link",
      },
      {
        "<leader>gy",
        function()
          require("gitlinker").get_buf_range_url("v")
        end,
        mode = "v",
        desc = "Copy git link",
      },
    },
    opts = { mappings = nil },
  },
}
