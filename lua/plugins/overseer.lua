return {
  'stevearc/overseer.nvim',
  cmd = {
    'OverseerOpen',
    'OverseerClose',
    'OverseerToggle',
    'OverseerRun',
    'OverseerRunCmd',
    'OverseerInfo',
    'OverseerBuild',
    'OverseerQuickAction',
    'OverseerTaskAction',
    'OverseerClearCache',
  },
  keys = {
    { '<leader>or', '<cmd>OverseerRun<cr>',         desc = 'Overseer: Run Task' },
    { '<leader>ot', '<cmd>OverseerToggle<cr>',      desc = 'Overseer: Toggle Panel' },
    { '<leader>oa', '<cmd>OverseerQuickAction<cr>', desc = 'Overseer: Quick Action' },
    { '<leader>oi', '<cmd>OverseerInfo<cr>',        desc = 'Overseer: Info' },
    { '<leader>ob', '<cmd>OverseerBuild<cr>',       desc = 'Overseer: Build Task' },
    { '<leader>oc', '<cmd>OverseerClearCache<cr>',  desc = 'Overseer: Clear Cache' },
  },
  config = function()
    local overseer = require('overseer')

    overseer.setup({
      strategy = 'terminal',
      task_list = {
        direction = 'bottom',
        min_height = 15,
        max_height = 25,
        default_detail = 1,
      },
    })

    local cargo_tasks = {
      { name = 'cargo build',         args = { 'build' } },
      { name = 'cargo build release', args = { 'build', '--release' } },
      { name = 'cargo run',           args = { 'run' } },
      { name = 'cargo run release',   args = { 'run', '--release' } },
      { name = 'cargo check',         args = { 'check' } },
      { name = 'cargo clippy',        args = { 'clippy', '--', '-D', 'warnings' } },
      { name = 'cargo clippy fix',    args = { 'clippy', '--fix', '--allow-dirty', '--allow-staged' } },
      { name = 'cargo test',          args = { 'test' } },
      { name = 'cargo test doc',      args = { 'test', '--doc' } },
      { name = 'cargo doc',           args = { 'doc', '--no-deps', '--open' } },
      { name = 'cargo bench',         args = { 'bench' } },
      { name = 'cargo fmt',           args = { 'fmt' } },
      { name = 'cargo fmt check',     args = { 'fmt', '--check' } },
      { name = 'cargo clean',         args = { 'clean' } },
      { name = 'cargo update',        args = { 'update' } },
      { name = 'cargo tree',          args = { 'tree' } },
    }

    for _, task in ipairs(cargo_tasks) do
      overseer.register_template({
        name = task.name,
        builder = function()
          return {
            cmd = { 'cargo' },
            args = task.args,
            components = { 'default' },
          }
        end,
        condition = {
          callback = function()
            return vim.fn.findfile('Cargo.toml', '.;') ~= ''
          end,
        },
      })
    end
  end,
}
