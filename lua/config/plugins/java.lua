local java_home_mod = require("config.java_home")

local function java_debug_bundles()
  local mason = vim.fn.stdpath("data") .. "/mason/packages"
  local bundles = vim.fn.glob(
    mason .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar",
    false,
    true
  )
  vim.list_extend(bundles, vim.fn.glob(mason .. "/java-test/extension/server/*.jar", false, true))
  return bundles
end

local function jdtls_layout()
  local data = vim.fn.stdpath("data")
  local roots = {
    data .. "/mason/packages/jdtls",
    data .. "/mason/share/jdtls",
  }
  local os_config = "config_linux"
  if vim.fn.has("mac") == 1 then
    os_config = "config_mac"
  elseif vim.fn.has("win32") == 1 then
    os_config = "config_win"
  end
  for _, root in ipairs(roots) do
    local jars = vim.fn.glob(root .. "/plugins/org.eclipse.equinox.launcher_*.jar", false, true)
    local jar = jars[1]
    if not jar and vim.fn.filereadable(root .. "/plugins/org.eclipse.equinox.launcher.jar") == 1 then
      jar = root .. "/plugins/org.eclipse.equinox.launcher.jar"
    end
    local config = root .. "/" .. os_config
    if vim.fn.isdirectory(config) == 0 then
      config = root .. "/config"
    end
    if jar and vim.fn.isdirectory(config) == 1 then
      local lombok = root .. "/lombok.jar"
      return {
        jar = jar,
        config = config,
        lombok = vim.fn.filereadable(lombok) == 1 and lombok or nil,
      }
    end
  end
  return nil
end

return {
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_blink, blink = pcall(require, "blink.cmp")
      if ok_blink then
        capabilities = blink.get_lsp_capabilities(capabilities)
      end

      local warned = false
      local function warn(message)
        if warned then
          return
        end
        warned = true
        vim.notify(message, vim.log.levels.ERROR)
      end

      local function attach()
        local fname = vim.api.nvim_buf_get_name(0)
        if fname == "" or vim.bo.filetype ~= "java" then
          return
        end

        local layout = jdtls_layout()
        if not layout then
          warn("jdtls is not installed. Run :MasonInstall jdtls, then reopen the Java file.")
          return
        end

        local found = java_home_mod.find()
        if not found then
          warn(java_home_mod.missing_message())
          return
        end
        local java_home = found.home
        local java_bin = found.bin

        local root_dir = vim.fs.root(fname, { "gradlew", "mvnw", "pom.xml", "build.gradle", "build.gradle.kts", ".git" })
        local project = root_dir and vim.fs.basename(root_dir) or "default"
        local cmd = {
          java_bin,
          "-Declipse.application=org.eclipse.jdt.ls.core.id1",
          "-Dosgi.bundles.defaultStartLevel=4",
          "-Declipse.product=org.eclipse.jdt.ls.core.product",
          "-Dlog.protocol=true",
          "-Dlog.level=ALL",
          "-Xmx1g",
          "--add-modules=ALL-SYSTEM",
          "--add-opens",
          "java.base/java.util=ALL-UNNAMED",
          "--add-opens",
          "java.base/java.lang=ALL-UNNAMED",
        }
        if layout.lombok then
          table.insert(cmd, "-javaagent:" .. layout.lombok)
        end
        vim.list_extend(cmd, {
          "-jar",
          layout.jar,
          "-configuration",
          layout.config,
          "-data",
          vim.fn.stdpath("cache") .. "/jdtls/" .. project .. "/workspace",
        })

        require("jdtls").start_or_attach({
          cmd = cmd,
          cmd_env = { JAVA_HOME = java_home },
          root_dir = root_dir,
          capabilities = capabilities,
          init_options = { bundles = java_debug_bundles() },
          settings = {
            java = {
              eclipse = { downloadSources = true },
              configuration = {
                updateBuildConfiguration = "automatic",
                runtimes = java_home_mod.runtimes(found),
              },
              maven = { downloadSources = true },
              implementationsCodeLens = { enabled = true },
              referencesCodeLens = { enabled = true },
              inlayHints = { parameterNames = { enabled = "all" } },
              signatureHelp = { enabled = true },
              completion = {
                favoriteStaticMembers = {
                  "org.assertj.core.api.Assertions.*",
                  "org.mockito.Mockito.*",
                },
              },
              sources = {
                organizeImports = { starThreshold = 5, staticStarThreshold = 3 },
              },
              codeGeneration = {
                toString = { template = "${class.name}{${member.name}=${member.value}, ${otherMembers}}" },
                hashCodeEquals = { useJava7Objects = true },
                useBlocks = true,
              },
            },
          },
        })
        pcall(require("jdtls").setup_dap, { hotcodereplace = "auto" })
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "java",
        callback = attach,
      })
      attach()
    end,
  },
}
