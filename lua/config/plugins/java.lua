local function sdkman_java(major)
  local base = vim.fn.expand("~/.sdkman/candidates/java")
  if vim.fn.isdirectory(base) == 0 then
    return nil
  end
  local matches = vim.fn.glob(base .. "/" .. tostring(major) .. "*", false, true)
  local dirs = {}
  for _, path in ipairs(matches) do
    if vim.fn.isdirectory(path) == 1 then
      table.insert(dirs, path)
    end
  end
  table.sort(dirs)
  return dirs[#dirs]
end

local function java_executable(home)
  if type(home) ~= "string" or home == "" then
    return nil
  end
  local names = { home .. "/bin/java", home .. "/bin/java.exe" }
  for _, bin in ipairs(names) do
    if vim.fn.executable(bin) == 1 then
      return bin
    end
  end
  return nil
end

local function home_of_java_bin(bin)
  if not bin or bin == "" then
    return nil
  end
  local home = vim.fn.fnamemodify(bin, ":h:h")
  if java_executable(home) then
    return home
  end
  return nil
end

local function find_java_home()
  local candidates = {
    vim.env.JAVA_HOME,
    vim.fn.expand("~/.local/nvim-tools/jdk"),
    sdkman_java(21),
    sdkman_java(17),
    vim.fn.expand("~/.sdkman/candidates/java/current"),
    home_of_java_bin(vim.fn.exepath("java")),
  }
  local jvms = vim.fn.glob("/usr/lib/jvm/*", false, true)
  table.sort(jvms)
  for _, path in ipairs(jvms) do
    table.insert(candidates, path)
  end
  for _, path in ipairs(candidates) do
    if java_executable(path) then
      return path
    end
  end
  return nil
end

local function java_major(bin)
  local out = vim.fn.system({ bin, "-version" })
  local quoted = out:match('version "([^"]+)"') or ""
  local modern = quoted:match("^(%d+)")
  local legacy = quoted:match("^1%.(%d+)")
  return tonumber(legacy or modern)
end

local function java_runtimes(fallback_home, fallback_major)
  local java21 = sdkman_java(21)
  local java17 = sdkman_java(17)
  local current = vim.fn.expand("~/.sdkman/candidates/java/current")
  if not java21 and vim.fn.isdirectory(current) == 1 then
    java21 = current
  end

  local runtimes = {}
  if java21 then
    table.insert(runtimes, { name = "JavaSE-21", path = java21, default = true })
  end
  if java17 then
    table.insert(runtimes, { name = "JavaSE-17", path = java17 })
  end
  if #runtimes == 0 and fallback_home then
    local name = fallback_major and ("JavaSE-" .. fallback_major) or "JavaSE"
    table.insert(runtimes, { name = name, path = fallback_home, default = true })
  end
  return runtimes
end

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

        local java_home = find_java_home()
        local java_bin = java_executable(java_home)
        if not java_bin then
          warn("No JDK found. Install one or set JAVA_HOME. This config also looks in ~/.local/nvim-tools/jdk.")
          return
        end
        local major = java_major(java_bin)
        if major and major < 17 then
          warn("jdtls needs JDK 17 or newer. Found Java " .. major .. " at " .. java_bin .. ".")
          return
        end

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
                runtimes = java_runtimes(java_home, major),
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
