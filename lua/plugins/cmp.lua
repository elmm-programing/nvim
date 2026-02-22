return {
  { -- Autocompletion
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      {
        'L3MON4D3/LuaSnip',
        version = '2.*',
        build = (function()
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then return end
          return 'make install_jsregexp'
        end)(),
        dependencies = {
          {
            'rafamadriz/friendly-snippets',
            config = function()
              require('luasnip.loaders.from_vscode').lazy_load()
              
              -- Share snippets between related languages
              local ls = require('luasnip')
              ls.filetype_extend('javascript', { 'javascriptreact' })
              ls.filetype_extend('typescript', { 'javascript' })
              ls.filetype_extend('typescriptreact', { 'typescript', 'html' })
              ls.filetype_extend('vue', { 'html', 'javascript', 'css' })
            end,
          },
        },
        opts = {},
      },
    },
    opts = {
      keymap = {
        preset = 'default',
        ['<CR>'] = { 'accept', 'fallback' },
        ['<C-j>'] = { 'select_next', 'fallback' },
        ['<C-k>'] = { 'select_prev', 'fallback' },
      },
      appearance = {
        nerd_font_variant = 'mono',
      },
      completion = {
        documentation = { auto_show = false, auto_show_delay_ms = 500 },
      },
      sources = {
        default = { 'lsp', 'path', 'snippets' },
      },
      snippets = { preset = 'luasnip' },
      fuzzy = { implementation = 'lua' },
      signature = { enabled = true },
    },
  },
}
