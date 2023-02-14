
local builtin = require('telescope.builtin')
vim.keymap.set('n', 'fc', require('telescope.builtin').commands, { desc = 'Get all commands' })
vim.keymap.set('n', 'fk', require('telescope.builtin').keymaps, { desc = 'Get all keymaps' })

vim.keymap.set('n', 'fb', require('telescope.builtin').buffers, { desc = '[ ] Find existing buffers' })
vim.keymap.set('n', '<leader>/', function()
  -- You can pass additional configuration to telescope to change theme, layout, etc.
  require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, { desc = '[/] Fuzzily search in current buffer]' })

vim.keymap.set('n', 'ff', require('telescope.builtin').find_files, { desc = '[S]earch [F]iles' })
-- vim.keymap.set('n', '<leader>sh', require('telescope.builtin').git_commits, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', 'fl', require('telescope.builtin').current_buffer_fuzzy_find, { desc = '[S]earch in current buffer' })
vim.keymap.set('n', 'fg', require('telescope.builtin').live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', require('telescope.builtin').diagnostics, { desc = '[S]earch [D]iagnostics' })

--vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
--vim.keymap.set('n', '<C-p>', builtin.git_files, {})
--vim.keymap.set('n', '<leader>ps', function()
--	builtin.grep_string({ search = vim.fn.input("grep > ") })
--end)
vim.keymap.set('n', '<leader>vh', builtin.help_tags, {})
-- Enable telescope fzf native, if installed
pcall(require('telescope').load_extension, 'fzf')
