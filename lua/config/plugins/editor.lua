return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    cmd = "Neotree",
    keys = {
      { "<leader>e", ":Neotree toggle<CR>", desc = "Toggle Neo-tree", silent = true },
      { "<leader>E", ":Neotree reveal<CR>", desc = "Reveal current file", silent = true },
    },
    opts = {
      close_if_last_window = true,
      enable_diagnostics = true,
      enable_git_status = true,
      filesystem = {
        filtered_items = {
          visible = false,
          hide_dotfiles = false,
          hide_gitignored = true,
          hide_by_name = {
            ".DS_Store",
            "thumbs.db",
            "node_modules",
          },
          hide_by_pattern = {
            "*.class",
            "*.o",
            "*.pyc",
          },
        },
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
        window = {
          mappings = {
            ["<CR>"] = "open",
            ["l"] = "open",
            ["h"] = "close_node",
            ["<C-s>"] = "open_split",
            ["<C-v>"] = "open_vsplit",
          },
        },
      },
    },
  },

  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
      "nvim-telescope/telescope-ui-select.nvim",
      "folke/todo-comments.nvim",
    },
    cmd = "Telescope",
    keys = {
      { "<leader>ff", ":Telescope find_files<CR>", desc = "Find files", silent = true },
      { "<leader>fg", ":Telescope live_grep<CR>", desc = "Live grep", silent = true },
      { "<leader>fb", ":Telescope buffers<CR>", desc = "Buffers", silent = true },
      { "<leader>fh", ":Telescope help_tags<CR>", desc = "Help tags", silent = true },
      { "<leader>fo", ":Telescope oldfiles<CR>", desc = "Recent files", silent = true },
      { "<leader>fc", ":Telescope commands<CR>", desc = "Commands", silent = true },
      { "<leader>fk", ":Telescope keymaps<CR>", desc = "Keymaps", silent = true },
      { "<leader>fd", ":Telescope diagnostics<CR>", desc = "Diagnostics", silent = true },
      { "<leader>fr", ":Telescope resume<CR>", desc = "Resume picker", silent = true },
      { "<leader>ft", ":TodoTelescope<CR>", desc = "Todo comments", silent = true },
      { "<leader>gf", ":Telescope git_files<CR>", desc = "Git files", silent = true },
      { "<leader>gb", ":Telescope git_branches<CR>", desc = "Git branches", silent = true },
      { "<leader>gL", ":Telescope git_commits<CR>", desc = "Git log", silent = true },
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")

      telescope.setup({
        defaults = {
          prompt_prefix = "❯ ",
          selection_caret = "▸ ",
          path_display = { "truncate" },
          sorting_strategy = "ascending",
          layout_config = {
            horizontal = { prompt_position = "top", preview_width = 0.55 },
            vertical = { mirror = false },
            width = 0.87,
            height = 0.80,
          },
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
              ["<Esc>"] = actions.close,
            },
            n = {
              ["q"] = actions.close,
              ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            },
          },
          file_ignore_patterns = {
            "node_modules",
            ".git/",
            "%.class",
            "%.o",
            "%.pyc",
          },
        },
        pickers = {
          find_files = {
            hidden = true,
          },
        },
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      })

      pcall(telescope.load_extension, "fzf")
      pcall(telescope.load_extension, "ui-select")
      pcall(telescope.load_extension, "projects")
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "windwp/nvim-ts-autotag",
    },
    config = function()
      local ts = require("nvim-treesitter.configs")

      ts.setup({
        ensure_installed = {
          "go",
          "gomod",
          "gosum",
          "gotmpl",
          "java",
          "javascript",
          "typescript",
          "tsx",
          "vue",
          "html",
          "css",
          "scss",
          "json",
          "jsonc",
          "yaml",
          "toml",
          "markdown",
          "markdown_inline",
          "lua",
          "vim",
          "vimdoc",
          "query",
          "regex",
          "bash",
          "dockerfile",
          "gitignore",
          "http",
        },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "gnn",
            node_incremental = "grn",
            node_decremental = "grm",
            scope_incremental = "grc",
          },
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["ia"] = "@parameter.inner",
              ["aa"] = "@parameter.outer",
            },
          },
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
              ["]m"] = "@function.outer",
              ["]]"] = "@class.outer",
            },
            goto_next_end = {
              ["]M"] = "@function.outer",
              ["]["] = "@class.outer",
            },
            goto_previous_start = {
              ["[m"] = "@function.outer",
              ["[["] = "@class.outer",
            },
            goto_previous_end = {
              ["[M"] = "@function.outer",
              ["[]"] = "@class.outer",
            },
          },
          swap = {
            enable = true,
            swap_next = {
              [">p"] = "@parameter.inner",
            },
            swap_previous = {
              ["<p"] = "@parameter.inner",
            },
          },
        },
      })
      pcall(function()
        require("nvim-ts-autotag").setup()
      end)
    end,
  },

  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "-", ":Oil<CR>", desc = "Open parent directory" },
    },
    opts = {
      default_file_explorer = false,
      view_options = { show_hidden = true },
    },
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    dependencies = { "echasnovski/mini.icons" },
    opts = {
      icons = { breadcrumb = "»", separator = "➜", group = "+", keys = { Space = "␣" } },
      win = { border = "rounded" },
      spec = {
        { "<leader>f", group = "file/find" },
        { "<leader>g", group = "git" },
        { "<leader>G", group = "go" },
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code" },
        { "<leader>d", group = "delete" },
        { "<leader>D", group = "debug" },
        { "<leader>w", group = "workspace/save" },
        { "<leader>t", group = "test" },
        { "<leader>x", group = "diagnostics" },
        { "<leader>h", group = "git hunk" },
        { "<leader>s", group = "search/symbols" },
        { "<leader>r", group = "refactor/REST" },
        { "<leader>u", group = "ui" },
        { "<leader>q", group = "quit/session" },
        { "<leader>j", group = "java" },
        { "<leader><tab>", group = "tabs" },
      },
    },
    keys = {
      {
        "<leader>?",
        function() require("which-key").show({ global = true }) end,
        desc = "All keymaps",
      },
    },
  },

  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "VeryLazy",
    opts = {
      signs = true,
    },
  },

  {
    "RRethy/vim-illuminate",
    event = "VeryLazy",
    opts = {
      delay = 200,
      filetypes_denylist = {
        "neo-tree",
        "TelescopePrompt",
        "alpha",
        "dashboard",
        "harpoon",
        "mason",
        "lazy",
      },
    },
    config = function(_, opts)
      require("illuminate").configure(opts)
    end,
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = "VeryLazy",
    opts = {
      indent = { char = "│" },
      scope = { enabled = true, show_start = false, show_end = false },
      exclude = {
        filetypes = {
          "help",
          "alpha",
          "dashboard",
          "neo-tree",
          "lazy",
          "mason",
          "toggleterm",
        },
      },
    },
  },

  {
    "echasnovski/mini.pairs",
    event = "VeryLazy",
    opts = {},
  },

  {
    "echasnovski/mini.surround",
    event = "VeryLazy",
    opts = {
      mappings = {
        add = "gsa",
        delete = "gsd",
        find = "gsf",
        find_left = "gsF",
        highlight = "gsh",
        replace = "gsr",
        update_n_lines = "gsn",
      },
    },
  },

  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
  },

  {
    "tpope/vim-sleuth",
    event = "VeryLazy",
  },

  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      notifier = { enabled = true },
      dashboard = { enabled = true },
      statuscolumn = { enabled = true },
      image = { enabled = false },
    },
  },
}
