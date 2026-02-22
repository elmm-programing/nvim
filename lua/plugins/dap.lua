return {
  'mfussenegger/nvim-dap',
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',
    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',
    -- Installs the visual text markers for debugger
    'theHamsta/nvim-dap-virtual-text',
    -- Installs Golang specific debugger configuration
    'leoluz/nvim-dap-go',
    -- Installs JS/TS/Vue specific debugger adapter
    'mxsdev/nvim-dap-vscode-js',
  },
  lazy = false,
  keys = {
    -- Basic debugging
    { '<leader>dc', function() require('dap').continue() end, desc = 'Debug: Start/Continue' },
    { '<leader>di', function() require('dap').step_into() end, desc = 'Debug: Step Into' },
    { '<leader>do', function() require('dap').step_over() end, desc = 'Debug: Step Over' },
    { '<leader>dO', function() require('dap').step_out() end, desc = 'Debug: Step Out' },
    
    -- Advanced stepping
    { '<leader>d-', function() require('dap').step_back() end, desc = 'Debug: Step Back' },
    { '<leader>d_', function() require('dap').reverse_continue() end, desc = 'Debug: Reverse Continue' },
    
    -- Execution flow
    { '<leader>dr', function() require('dap').restart() end, desc = 'Debug: Restart' },
    { '<leader>dx', function() require('dap').terminate() end, desc = 'Debug: Stop/Terminate' },
    { '<leader>dp', function() require('dap').pause() end, desc = 'Debug: Pause' },
    { '<leader>dg', function() require('dap').goto_() end, desc = 'Debug: Go to line (no execute)' },
    
    -- Breakpoints
    { '<leader>db', function() require('dap').toggle_breakpoint() end, desc = 'Debug: Toggle Breakpoint' },
    { '<leader>dB', function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, desc = 'Debug: Set Breakpoint Condition' },
    { '<leader>dl', function() require('dap').set_breakpoint(nil, nil, vim.fn.input 'Log point message: ') end, desc = 'Debug: Set Logpoint' },
    { '<leader>dE', function() require('dap').set_exception_breakpoints() end, desc = 'Debug: Set Exception Breakpoints' },

    -- REPL and evaluation
    { '<leader>dR', function() require('dap').repl.toggle() end, desc = 'Debug: Toggle REPL' },
    { '<leader>de', function() require('dapui').eval() end, desc = 'Debug: Evaluate Expression', mode = {'n', 'v'} },
    
    -- Toggle UI
    { '<leader>du', function() require('dapui').toggle() end, desc = 'Debug: See last session result.' },

    -- Golang specific
    { '<leader>dgt', function() require('dap-go').debug_test() end, desc = 'Debug: Go Test' },
    { '<leader>dgl', function() require('dap-go').debug_last_test() end, desc = 'Debug: Go Last Test' },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('nvim-dap-virtual-text').setup()
    
    require('dapui').setup()
    
    require('dap-go').setup()

    -- Setup javascript/typescript/vue debugger
    require('dap-vscode-js').setup {
      debugger_path = vim.fn.stdpath 'data' .. '/mason/packages/js-debug-adapter',
      adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' },
    }

    local js_based_languages = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact', 'vue' }

    for _, language in ipairs(js_based_languages) do
      dap.configurations[language] = {
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Launch file (Node)',
          program = '${file}',
          cwd = '${workspaceFolder}',
        },
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Launch Nuxt 3 (Node)',
          cwd = '${workspaceFolder}',
          runtimeExecutable = 'npx',
          runtimeArgs = { 'nuxi', 'dev' },
          skipFiles = { '<node_internals>/**' },
        },
        {
          type = 'pwa-node',
          request = 'attach',
          name = 'Attach to process (Node)',
          processId = require('dap.utils').pick_process,
          cwd = '${workspaceFolder}',
        },
        {
          type = 'pwa-chrome',
          request = 'launch',
          name = 'Launch Chrome against localhost',
          url = 'http://localhost:3000',
          webRoot = '${workspaceFolder}',
          userDataDir = '${workspaceFolder}/.vscode/vscode-chrome-debug-userdatadir',
          sourceMapPathOverrides = {
            -- Nuxt 3 source maps
            ['webpack:///./*'] = '${webRoot}/*',
            ['webpack:///src/*'] = '${webRoot}/*',
            ['webpack:///*'] = '*',
          },
        },
      }
    end

    -- Allow loading configurations from a local .vscode/launch.json
    -- Wrap in an existence check so it doesn't wipe our custom configs when missing
    if vim.fn.filereadable('.vscode/launch.json') == 1 then
      require('dap.ext.vscode').load_launchjs(nil, {
        ['pwa-node'] = js_based_languages,
        ['pwa-chrome'] = js_based_languages,
        ['node-terminal'] = js_based_languages,
      })
    end

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close
  end,
}
