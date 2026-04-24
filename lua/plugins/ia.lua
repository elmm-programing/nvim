-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║              Claude Code (claudecode.nvim) — Cheatsheet              ║
-- ╠══════════════════════════════════════════════════════════════════════╣
-- ║ Quick start:                                                         ║
-- ║   1. Open any code file                                              ║
-- ║   2. <leader>ac  → opens Claude in a right-side vertical split       ║
-- ║   3. Ask Claude to do something; review the proposed diff with       ║
-- ║      <leader>aa to accept, <leader>ad to deny                        ║
-- ╠══════════════════════════════════════════════════════════════════════╣
-- ║ <leader>ac   Toggle Claude (vertical split, right side)              ║
-- ║ <leader>af   Focus the Claude window                                 ║
-- ║ <leader>ar   Resume a previous Claude session                        ║
-- ║ <leader>aC   Continue the last Claude conversation                   ║
-- ║ <leader>am   Select Claude model                                     ║
-- ║ <leader>ab   Add the current buffer to Claude's context              ║
-- ║ <leader>as   (visual mode) Send selection to Claude                  ║
-- ║ <leader>as   (in neo-tree) Add the file under cursor                 ║
-- ║ <leader>aF   Add files via Telescope (use <Tab> to multi-select)     ║
-- ║ <leader>aa   Accept the proposed diff                                ║
-- ║ <leader>ad   Deny the proposed diff                                  ║
-- ╚══════════════════════════════════════════════════════════════════════╝

local function telescope_claude_add()
  local ok_builtin, builtin = pcall(require, 'telescope.builtin')
  if not ok_builtin then
    vim.notify('telescope.nvim is not available', vim.log.levels.WARN)
    return
  end
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  builtin.find_files {
    prompt_title = 'Add files to Claude (Tab to multi-select)',
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local selections = picker:get_multi_selection()
        if vim.tbl_isempty(selections) then
          local entry = action_state.get_selected_entry()
          if entry then
            selections = { entry }
          end
        end
        actions.close(prompt_bufnr)
        for _, sel in ipairs(selections) do
          local path = sel.path or sel.filename or sel.value
          if path and path ~= '' then
            vim.cmd('ClaudeCodeAdd ' .. vim.fn.fnameescape(path))
          end
        end
      end)
      return true
    end,
  }
end

return {
  {
    'coder/claudecode.nvim',
    dependencies = { 'folke/snacks.nvim' },
    opts = {
      terminal = {
        split_side = 'right',
        split_width_percentage = 0.40,
      },
      diff_opts = {
        layout = 'vertical',
        open_in_current_tab = true,
      },
    },
    keys = {
      { '<leader>a', nil, desc = 'AI/Claude Code' },
      { '<leader>ac', '<cmd>ClaudeCode<cr>', desc = 'Toggle Claude' },
      { '<leader>af', '<cmd>ClaudeCodeFocus<cr>', desc = 'Focus Claude' },
      { '<leader>ar', '<cmd>ClaudeCode --resume<cr>', desc = 'Resume Claude' },
      { '<leader>aC', '<cmd>ClaudeCode --continue<cr>', desc = 'Continue Claude' },
      { '<leader>am', '<cmd>ClaudeCodeSelectModel<cr>', desc = 'Select Claude model' },
      { '<leader>ab', '<cmd>ClaudeCodeAdd %<cr>', desc = 'Add current buffer' },
      { '<leader>as', '<cmd>ClaudeCodeSend<cr>', mode = 'v', desc = 'Send selection to Claude' },
      {
        '<leader>as',
        '<cmd>ClaudeCodeTreeAdd<cr>',
        desc = 'Add file from tree',
        ft = { 'neo-tree' },
      },
      { '<leader>aF', telescope_claude_add, desc = 'Add files (Telescope, Tab to multi-select)' },
      { '<leader>aa', '<cmd>ClaudeCodeDiffAccept<cr>', desc = 'Accept diff' },
      { '<leader>ad', '<cmd>ClaudeCodeDiffDeny<cr>', desc = 'Deny diff' },
    },
  },
}
