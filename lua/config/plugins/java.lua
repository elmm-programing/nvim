local function sdkman_java(major)
  local base = vim.fn.expand '~/.sdkman/candidates/java'
  if vim.fn.isdirectory(base) == 0 then
    return nil
  end

  local matches = vim.fn.glob(base .. '/' .. tostring(major) .. '*', false, true)
  local dirs = {}
  for _, path in ipairs(matches) do
    if vim.fn.isdirectory(path) == 1 then
      table.insert(dirs, path)
    end
  end
  table.sort(dirs)
  return dirs[#dirs]
end

local function java_runtimes()
  local java21 = sdkman_java(21)
  local java17 = sdkman_java(17)
  local current = vim.fn.expand '~/.sdkman/candidates/java/current'
  if not java21 and vim.fn.isdirectory(current) == 1 then
    java21 = current
  end

  local runtimes = {}
  if java21 then
    table.insert(runtimes, { name = 'JavaSE-21', path = java21, default = true })
  end
  if java17 then
    table.insert(runtimes, { name = 'JavaSE-17', path = java17 })
  end
  if #runtimes == 0 then
    local java_home = vim.env.JAVA_HOME
    if java_home and vim.fn.isdirectory(java_home) == 1 then
      table.insert(runtimes, { name = 'JavaSE', path = java_home, default = true })
    end
  end
  return runtimes
end

local function java_debug_bundles()
  local mason = vim.fn.stdpath 'data' .. '/mason/packages'
  local bundles = vim.fn.glob(mason .. '/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar', false, true)
  vim.list_extend(bundles, vim.fn.glob(mason .. '/java-test/extension/server/*.jar', false, true))
  return bundles
end

return {
  {
    'mfussenegger/nvim-jdtls',
    ft = 'java',
    dependencies = { 'mfussenegger/nvim-dap' },
    config = function()
      local capabilities = require('blink.cmp').get_lsp_capabilities(vim.lsp.protocol.make_client_capabilities())
      local mason_jdtls = vim.fn.stdpath 'data' .. '/mason/packages/jdtls'
      local cmd = { mason_jdtls .. '/jdtls' }
      local lombok = mason_jdtls .. '/lombok.jar'
      if vim.fn.filereadable(lombok) == 1 then
        table.insert(cmd, '--jvm-arg=-javaagent:' .. lombok)
      end

      local function attach()
        local fname = vim.api.nvim_buf_get_name(0)
        local root_dir = vim.fs.root(fname, { 'gradlew', 'mvnw', 'pom.xml', 'build.gradle', 'build.gradle.kts', '.git' })
        local project = root_dir and vim.fs.basename(root_dir) or 'default'
        local full_cmd = vim.deepcopy(cmd)
        vim.list_extend(full_cmd, {
          '-configuration',
          vim.fn.stdpath 'cache' .. '/jdtls/' .. project .. '/config',
          '-data',
          vim.fn.stdpath 'cache' .. '/jdtls/' .. project .. '/workspace',
        })

        require('jdtls').start_or_attach {
          cmd = full_cmd,
          root_dir = root_dir,
          capabilities = capabilities,
          init_options = { bundles = java_debug_bundles() },
          settings = {
            java = {
              eclipse = { downloadSources = true },
              configuration = {
                updateBuildConfiguration = 'automatic',
                runtimes = java_runtimes(),
              },
              maven = { downloadSources = true },
              implementationsCodeLens = { enabled = true },
              referencesCodeLens = { enabled = true },
              inlayHints = { parameterNames = { enabled = 'all' } },
              signatureHelp = { enabled = true },
              completion = {
                favoriteStaticMembers = {
                  'org.assertj.core.api.Assertions.*',
                  'org.mockito.Mockito.*',
                },
              },
              sources = {
                organizeImports = { starThreshold = 5, staticStarThreshold = 3 },
              },
              codeGeneration = {
                toString = { template = '${class.name}{${member.name}=${member.value}, ${otherMembers}}' },
                hashCodeEquals = { useJava7Objects = true },
                useBlocks = true,
              },
            },
          },
        }
      end

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'java',
        callback = attach,
      })
      attach()
    end,
  },
}
