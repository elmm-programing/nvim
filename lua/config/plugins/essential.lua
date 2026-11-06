return {
  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons", "SmiteshP/nvim-navic" },
    opts = function()
      local root_markers = { ".git", "package.json", "nuxt.config.ts", "nuxt.config.js", "go.mod", "pom.xml", "build.gradle" }

      local function project_name()
        local cwd = vim.fn.getcwd()
        local root = vim.fs.root(0, root_markers)
        if not root or root == cwd then
          return ""
        end
        return vim.fs.basename(root) .. " "
      end

      local function pretty_path()
        local name = vim.api.nvim_buf_get_name(0)
        if name == "" then
          return "[No Name]"
        end
        local relative = vim.fn.fnamemodify(name, ":.")
        local parts = vim.split(relative, "[/\\]", { trimempty = true })
        if #parts > 3 then
          return parts[1] .. "/…/" .. parts[#parts]
        end
        return relative
      end

      local function recording()
        local reg = vim.fn.reg_recording()
        if reg == "" then
          return ""
        end
        return "recording @" .. reg
      end

      vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave", "CursorMoved" }, {
        group = vim.api.nvim_create_augroup("LualineRefresh", { clear = true }),
        callback = function()
          pcall(function()
            require("lualine").refresh({ place = { "statusline" } })
          end)
        end,
      })

      return {
        options = {
          theme = "auto",
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
          disabled_filetypes = { statusline = { "dashboard", "alpha", "neo-tree", "snacks_dashboard" } },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch" },
          lualine_c = {
            { project_name, color = { gui = "bold" } },
            { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
            { pretty_path },
            {
              "navic",
              cond = function()
                return package.loaded["nvim-navic"] and require("nvim-navic").is_available()
              end,
            },
          },
          lualine_x = {
            { recording, color = { gui = "bold" } },
            "diagnostics",
            "diff",
          },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
        extensions = { "neo-tree", "lazy", "mason", "trouble" },
      }
    end,
  },

  {
    "b0o/incline.nvim",
    event = "BufReadPre",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local devicons = require("nvim-web-devicons")
      require("incline").setup({
        hide = { cursorline = true },
        window = {
          margin = { vertical = 0, horizontal = 1 },
          placement = { horizontal = "right", vertical = "top" },
        },
        render = function(props)
          local bufname = vim.api.nvim_buf_get_name(props.buf)
          local filename = bufname ~= "" and vim.fn.fnamemodify(bufname, ":t") or "[No Name]"
          local items = {}
          if vim.bo[props.buf].modified then
            table.insert(items, { "[+] ", group = "WarningMsg" })
          end
          local icon, color = devicons.get_icon_color(filename)
          if icon then
            table.insert(items, { icon .. " ", guifg = color })
          end
          table.insert(items, { filename })
          return items
        end,
      })
    end,
  },

  -- Buffer tabs
  {
    "akinsho/bufferline.nvim",
    -- PR #1051: vim.nonnil when available (checkhealth vim.F.if_nil).
    -- Not on bufferline main (still 4.9.1); pin the commit.
    commit = "24f6ae78b1fcb01b66e806c0373ec46a15f0f66d",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        mode = "buffers",
        numbers = "none",
        close_command = "bdelete! %d",
        right_mouse_command = "bdelete! %d",
        left_mouse_command = "buffer %d",
        middle_mouse_command = nil,
        indicator = { style = "icon", icon = "▎" },
        buffer_close_icon = "󰅖",
        modified_icon = "●",
        close_icon = "",
        left_trunc_marker = "",
        right_trunc_marker = "",
        max_name_length = 30,
        max_prefix_length = 30,
        tab_size = 21,
        diagnostics = "nvim_lsp",
        diagnostics_update_in_insert = false,
        diagnostics_indicator = function(count, level)
          local icon = level:match("error") and " " or " "
          return " " .. icon .. count
        end,
        offsets = {
          {
            filetype = "neo-tree",
            text = "File Explorer",
            highlight = "Directory",
            separator = true,
            text_align = "left",
          },
        },
        show_buffer_icons = true,
        show_buffer_close_icons = true,
        show_close_icon = false,
        show_tab_indicators = true,
        persist_buffer_sort = true,
        separator_style = "thin",
        enforce_regular_tabs = false,
        always_show_bufferline = true,
        sort_by = "insert_after_current",
      },
    },
  },

  -- Better diagnostics list
  {
    "folke/trouble.nvim",
    cmd = { "Trouble", "TroubleToggle", "TroubleRefresh" },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
      { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)" },
      { "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP Definitions / references / ... (Trouble)" },
      { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
      { "[q", function()
        if require("trouble").is_open() then
          require("trouble").prev({ skip_groups = true, jump = true })
        else
          local ok, err = pcall(vim.cmd.cprev)
          if not ok then vim.notify(err, vim.log.levels.ERROR) end
        end
      end, desc = "Previous trouble/quickfix item" },
      { "]q", function()
        if require("trouble").is_open() then
          require("trouble").next({ skip_groups = true, jump = true })
        else
          local ok, err = pcall(vim.cmd.cnext)
          if not ok then vim.notify(err, vim.log.levels.ERROR) end
        end
      end, desc = "Next trouble/quickfix item" },
    },
    opts = {
      auto_open = false,
      auto_close = true,
      auto_preview = true,
      auto_jump = { "lsp_definitions" },
      focus = true,
      follow = true,
      restore = true,
      indent_guides = true,
      max_items = 200,
      multiline = true,
    },
  },

  -- Better navigation
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      modes = {
        char = {
          enabled = true,
          jump_labels = true,
        },
      },
    },
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
  },

  -- Yank history
  {
    "gbprod/yanky.nvim",
    event = "VeryLazy",
    keys = {
      { "<leader>y", function() require("yanky.history").show() end, desc = "Yank history" },
      { "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank" },
      { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put after" },
      { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put before" },
      { "gp", "<Plug>(YankyGPutAfter)", mode = { "n", "x" }, desc = "Put after (cursor stays)" },
      { "gP", "<Plug>(YankyGPutBefore)", mode = { "n", "x" }, desc = "Put before (cursor stays)" },
      { "<c-n>", "<Plug>(YankyCycleForward)", desc = "Cycle forward through yank history" },
      { "<c-p>", "<Plug>(YankyCycleBackward)", desc = "Cycle backward through yank history" },
    },
    opts = {
      ring = { history_length = 100, storage = "shada", sync_with_numbered_registers = true },
      highlight = { on_put = true, on_yank = true, timer = 500 },
      preserve_cursor_position = { enabled = true },
    },
  },

  -- Code refactoring
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    keys = {
      { "<leader>re", function() require("refactoring").refactor("Extract Function") end, mode = "v", desc = "Extract Function" },
      { "<leader>rf", function() require("refactoring").refactor("Extract Function To File") end, mode = "v", desc = "Extract Function To File" },
      { "<leader>rv", function() require("refactoring").refactor("Extract Variable") end, mode = "v", desc = "Extract Variable" },
      { "<leader>ri", function() require("refactoring").refactor("Inline Variable") end, mode = { "n", "v" }, desc = "Inline Variable" },
      { "<leader>rb", function() require("refactoring").refactor("Extract Block") end, mode = "n", desc = "Extract Block" },
      { "<leader>rbf", function() require("refactoring").refactor("Extract Block To File") end, mode = "n", desc = "Extract Block To File" },
      { "<leader>rr", function() require("refactoring").select_refactor() end, mode = "v", desc = "Select Refactor" },
    },
    opts = {
      show_success_message = true,
    },
  },

  -- Breadcrumbs
  {
    "SmiteshP/nvim-navic",
    lazy = true,
    init = function()
      vim.g.navic_silence = true
    end,
    opts = {
      separator = " › ",
      highlight = true,
      depth_limit = 5,
    },
  },

  -- vim.ui.input is snacks.input; vim.ui.select is telescope-ui-select

  -- Search and replace (spectre)
  {
    "nvim-pack/nvim-spectre",
    cmd = "Spectre",
    keys = {
      { "<leader>sr", function() require("spectre").open() end, desc = "Replace in files (Spectre)" },
    },
    opts = {
      open_cmd = "vnew",
      live_update = true,
      line_sep_start = "┌-----------------------------------------",
      result_padding = "¦  ",
      line_sep = "└-----------------------------------------",
      highlight = {
        ui = "String",
        search = "DiffChange",
        replace = "DiffDelete",
      },
      mapping = {
        ["tab"] = {
          map = "<Tab>",
          cmd = "<cmd>lua require('spectre').tab()<cr>",
          desc = "next query",
        },
        ["shift-tab"] = {
          map = "<S-Tab>",
          cmd = "<cmd>lua require('spectre').shift_tab()<cr>",
          desc = "previous query",
        },
        ["toggle_line"] = {
          map = "dd",
          cmd = "<cmd>lua require('spectre').toggle_line()<CR>",
          desc = "toggle item",
        },
        ["enter_file"] = {
          map = "<cr>",
          cmd = "<cmd>lua require('spectre').enter_file()<CR>",
          desc = "goto file",
        },
        ["send_to_qf"] = {
          map = "",
          cmd = "<cmd>lua require('spectre').send_to_qf()<CR>",
          desc = "send all items to quickfix",
        },
        ["replace_cmd"] = {
          map = "",
          cmd = "<cmd>lua require('spectre').replace_cmd()<CR>",
          desc = "input replace command",
        },
        ["show_option_menu"] = {
          map = "<leader>o",
          cmd = "<cmd>lua require('spectre').show_options()<CR>",
          desc = "show options",
        },
        ["run_current_replace"] = {
          map = "<leader>rc",
          cmd = "<cmd>lua require('spectre').run_current_replace()<CR>",
          desc = "replace current line",
        },
        ["run_replace"] = {
          map = "<leader>R",
          cmd = "<cmd>lua require('spectre').run_replace()<CR>",
          desc = "replace all",
        },
        ["change_view_mode"] = {
          map = "<leader>v",
          cmd = "<cmd>lua require('spectre').change_view()<CR>",
          desc = "change result view mode",
        },
      },
    },
  },

  -- Better terminal
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = "ToggleTerm",
    keys = {
      { "<leader>\\", "<cmd>ToggleTerm direction=float<cr>", desc = "Toggle floating terminal" },
    },
    opts = {
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,
      open_mapping = [[<c-\>]],
      hide_numbers = true,
      shade_filetypes = {},
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      insert_mappings = true,
      persist_size = true,
      direction = "float",
      close_on_exit = true,
      shell = vim.o.shell,
      float_opts = {
        border = "curved",
        winblend = 0,
        highlights = {
          border = "Normal",
          background = "Normal",
        },
      },
    },
  },

  -- Better quickfix
  {
    "kevinhwang91/nvim-bqf",
    ft = "qf",
    opts = {
      auto_enable = true,
      auto_resize_height = true,
      preview = {
        win_height = 12,
        win_vheight = 12,
        delay_syntax = 80,
        border_chars = { "┃", "┃", "━", "━", "┏", "┓", "┗", "┛", "█" },
        show_title = false,
        should_preview_cb = function(bufnr, qwinid)
          local ret = true
          local bufname = vim.api.nvim_buf_get_name(bufnr)
          local fsize = vim.fn.getfsize(bufname)
          if fsize > 100 * 1024 then
            ret = false
          elseif bufname:match("^fugitive://") then
            ret = false
          end
          return ret
        end,
      },
      func = {
        copen = function(qwinid)
          vim.api.nvim_set_current_win(qwinid)
        end,
      },
      filter = {
        fzf = {
          action_for = {
            ["ctrl-s"] = "split",
            ["ctrl-v"] = "vsplit",
            ["ctrl-t"] = "tabedit",
            ["ctrl-q"] = "signtoggle",
            ["ctrl-c"] = "close",
          },
          extra_opts = { "--bind", "ctrl-o:toggle-all", "--prompt", " > " },
        },
      },
    },
  },
}
