
-----------------------------------------------------------
-- Define keymaps of Neovim and installed plugins.
-----------------------------------------------------------

-- Change leader to a comma
vim.g.mapleader = ','
vim.g.maplocalleader = ','


-----------------------------------------------------------
-- Neovim shortcuts
-----------------------------------------------------------

-- Map Esc to kk
vim.keymap.set('i', 'kj', '<Esc>')

-- [[ Basic Keymaps ]]
-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })




-- Move around splits using Ctrl + {h,j,k,l}
vim.keymap.set('n', '<C-H>', '<C-W>h')
vim.keymap.set('n', '<C-J>', '<C-W>j')
vim.keymap.set('n', '<C-K>', '<C-W>k')
vim.keymap.set('n', '<C-L>', '<C-W>l')



-- Close all windows and exit from Neovim with <leader> and q
vim.cmd [[
nnoremap  <silent>   <tab>  :if &modifiable && !&readonly && &modified <CR> :write<CR> :endif<CR>:bnext<CR>
kj
nnoremap  <silent> <s-tab>  :if &modifiable && !&readonly && &modified <CR> :write<CR> :endif<CR>:bprevious<CR>
]]

vim.keymap.set('n', '<leader>nt', ':NERDTreeFind<CR>')
vim.keymap.set('n', '<leader>w', ':w<CR>')
vim.keymap.set('n', '<leader>q', ':q<CR>')
vim.keymap.set('n', '<leader>wq', ':wq<CR>')
vim.keymap.set('n', '<S-l> ', ':bnext<CR>')
vim.keymap.set('n', '<S-h> ', ':bprevious<CR>')
-- map('n', '<Leader>t ', ':Vista coc<CR>')

-- map('n', 'fg', ':Rg<CR>')
-- map('n', 'fa', ':Ag<CR>')
-- map('n', 'fb', ':Buffers<CR>')
-- map('n', 'fl', ':BLines<CR>')
-- map('n', 'fc', ':Commands<CR>')


-- map('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
-- map('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>')
-- map('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>')
-- map('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
-- map('n', '<C-a>', '<cmd>lua vim.lsp.buf.code_action()<CR>')


-----------------------------------------------------------
-- Applications and Plugins shortcuts
-----------------------------------------------------------

-- Tagbar
--
-- Diagnostic keymaps
-- vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
-- vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
-- vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
-- vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)
