local lsp = require("lsp-zero")

lsp.preset("recommended")

-- lsp.ensure_installed({
--   'tsserver'
-- })
--
-- Fix Undefined global 'vim'
-- lsp.configure('sumneko_lua', {
--     settings = {
--         Lua = {
--             diagnostics = {
--                 globals = { 'vim' }
--             }
--         }
--     }
-- })


local cmp = require('cmp')
local luasnip = require('luasnip')

lsp.setup_nvim_cmp({
mapping =  cmp.mapping.preset.insert {
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  },
   snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  formatting = {
  fields = {'menu', 'abbr', 'kind'},
  format = function(entry, item)
    local menu_icon = {
      nvim_lsp = 'λ',
      luasnip = '⋗',
      buffer = 'Ω',
      path = '🖫',
      cmp_tabnine='🧠',
    }

    item.menu = menu_icon[entry.source.name]
    return item
  end,
},
sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'cmp_tabnine' },
  },
})

lsp.set_preferences({
    suggest_lsp_servers = false,
    sign_icons = {
error = "", warn = "", hint = "", info = ""
    }
})

lsp.on_attach(function(client, bufnr)
  local opts = {buffer = bufnr, remap = false}

  vim.keymap.set("n", "<leader>rn", function() vim.lsp.buf.rename() end, opts)

  vim.keymap.set("n", "<leader>ca", function() vim.lsp.buf.code_action() end, opts)
  vim.keymap.set("n", "<C-a>", function() vim.lsp.buf.code_action() end, opts)

  vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
  vim.keymap.set("n", "gr", function() require('telescope.builtin').lsp_references() end, opts)
  vim.keymap.set("n", "gi", function() vim.lsp.buf.implementation() end, opts)

  vim.keymap.set("n", "<leader>D", function() vim.lsp.buf.type_definition() end, opts)
  vim.keymap.set("n", "<leader>ds", function() require('telescope.builtin').lsp_document_symbols() end, opts)
  vim.keymap.set("n", "<leader>ws", function() require('telescope.builtin').lsp_dynamic_workspace_symbols() end, opts)

  vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
  vim.keymap.set("n", "<C-k>", function() vim.lsp.buf.signature_help() end, opts)

  vim.keymap.set("n", "gD", function() vim.lsp.buf.declaration() end, opts)

  vim.keymap.set("n", "<leader>wa", function() vim.lsp.buf.add_workspace_folder() end, opts)
  vim.keymap.set("n", "<leader>wr", function() vim.lsp.buf.remove_workspace_folder() end, opts)
  vim.keymap.set("n", "<leader>wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, opts)

  vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
  vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
  vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
  vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
 -- Create a command `:Format` local to the LSP buffer
  vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
    vim.lsp.buf.format()
  end, { desc = 'Format current buffer with LSP' })
end
)

lsp.setup()

vim.diagnostic.config({
    virtual_text = true
})

-- this is for diagnositcs signs on the line number column
-- use this to beautify the plain E W signs to more fun ones
-- !important nerdfonts needs to be setup for this to work in your terminal
local signs = {  }
for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl= hl, numhl = hl })
end
