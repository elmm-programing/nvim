return {
  {
    "saghen/blink.cmp",
    version = "1.*",
    lazy = false,
    dependencies = {
      "rafamadriz/friendly-snippets",
      {
        "L3MON4D3/LuaSnip",
        version = "v2.*",
        build = "make install_jsregexp",
        config = function()
          local ls = require("luasnip")
          require("luasnip.loaders.from_vscode").lazy_load()
          require("luasnip.loaders.from_vscode").lazy_load({ paths = { vim.fn.stdpath("config") .. "/snippets" } })

          ls.config.set_config({
            history = true,
            update_events = "TextChanged,TextChangedI",
            delete_check_events = "TextChanged",
            enable_autosnippets = true,
            store_selection_keys = "<Tab>",
          })
        end,
      },
      "folke/lazydev.nvim",
    },
    opts = {
      keymap = {
        preset = "default",
        ["<Tab>"] = { "snippet_forward", "select_and_accept", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide", "fallback" },
      },
      appearance = {
        nerd_font_variant = "mono",
      },
      completion = {
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          treesitter_highlighting = true,
          window = { border = "rounded" },
        },
        ghost_text = { enabled = true },
        menu = { border = "rounded", draw = { padding = 1 } },
      },
      signature = { enabled = true, window = { border = "rounded" } },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        per_filetype = {
          lua = { inherit_defaults = true, "lazydev" },
        },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },
        },
      },
      snippets = { preset = "luasnip" },
    },
  },

  -- LuaSnip keymaps: expand + jump through tabstops
  {
    "L3MON4D3/LuaSnip",
    keys = {
      { "<Tab>", function() require("luasnip").jump(1) end, mode = "s", desc = "Next snippet tabstop", silent = true },
      { "<S-Tab>", function() require("luasnip").jump(-1) end, mode = "s", desc = "Prev snippet tabstop", silent = true },
      { "<C-j>", function() require("luasnip").expand_or_jump() end, mode = { "i", "s" }, desc = "Expand/jump snippet", silent = true },
    },
  },
}
