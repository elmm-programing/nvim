return {
  -- Session management
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {
      dir = vim.fn.stdpath("state") .. "/sessions/",
    },
    keys = {
      { "<Leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
      { "<Leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
      { "<Leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
      { "<Leader>qS", function() require("persistence").save() end, desc = "Save Session" },
    },
  },

  -- Project management
  {
    "ahmedkhalf/project.nvim",
    event = "VeryLazy",
    opts = {
      manual_mode = true,
      detection_methods = { "pattern", "lsp" },
      patterns = {
        ".git",
        "package.json",
        "go.mod",
        "pom.xml",
        "build.gradle",
        "build.gradle.kts",
        "nuxt.config.ts",
        "nuxt.config.js",
      },
      show_hidden = false,
      silent_chdir = true,
      scope_chdir = "global",
      datapath = vim.fn.stdpath("data"),
    },
    config = function(_, opts)
      require("project_nvim").setup(opts)
    end,
    keys = {
      { "<leader>fp", "<cmd>Telescope projects<cr>", desc = "Find projects" },
      { "<leader>fP", "<cmd>ProjectRoot<cr>", desc = "Set cwd to project root" },
    },
  },

  -- Harpoon for quick file navigation
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      settings = {
        save_on_toggle = true,
        sync_on_ui_close = true,
      },
    },
    config = function(_, opts)
      require("harpoon"):setup(opts)
    end,
    keys = {
      { "<leader>a", function() require("harpoon"):list():add() end, desc = "Add to harpoon" },
      {
        "<leader>A",
        function()
          local harpoon = require("harpoon")
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "Harpoon menu",
      },
      { "<leader>1", function() require("harpoon"):list():select(1) end, desc = "Harpoon file 1" },
      { "<leader>2", function() require("harpoon"):list():select(2) end, desc = "Harpoon file 2" },
      { "<leader>3", function() require("harpoon"):list():select(3) end, desc = "Harpoon file 3" },
      { "<leader>4", function() require("harpoon"):list():select(4) end, desc = "Harpoon file 4" },
      { "<leader>5", function() require("harpoon"):list():select(5) end, desc = "Harpoon file 5" },
      { "<C-S-P>", function() require("harpoon"):list():prev() end, desc = "Previous harpoon file" },
      { "<C-S-N>", function() require("harpoon"):list():next() end, desc = "Next harpoon file" },
    },
  },
}
