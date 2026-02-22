local jdtls = require('jdtls')

local mason_path = vim.fn.stdpath('data') .. '/mason/packages'
local bundles = {}

local function add_bundle(path)
  local jars = vim.split(vim.fn.glob(path), '\n')
  for _, jar in ipairs(jars) do
    if jar ~= "" then table.insert(bundles, jar) end
  end
end

-- Add Java Debug, Java Test, and Spring Boot Tools to JDTLS
add_bundle(mason_path .. '/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar')
add_bundle(mason_path .. '/java-test/extension/server/*.jar')
add_bundle(mason_path .. '/vscode-spring-boot-tools/extension/jars/*.jar')

-- Discover JDKs on macOS and Linux (SDKMAN) dynamically
local function get_runtimes()
  local runtimes = {}
  local paths_to_scan = {
    "/Library/Java/JavaVirtualMachines",
    vim.fn.expand("~/.sdkman/candidates/java"),
  }
  
  local found = {}

  for _, base_path in ipairs(paths_to_scan) do
    if vim.fn.isdirectory(base_path) == 1 then
      local handle = vim.uv.fs_scandir(base_path)
      if handle then
        while true do
          local name, type = vim.uv.fs_scandir_next(handle)
          if not name then break end
          if type == "directory" or type == "link" then
            local full_path = base_path .. "/" .. name
            
            -- macOS specific pathing
            if base_path:match("JavaVirtualMachines") then
              full_path = full_path .. "/Contents/Home"
            end
            
            -- Guess Java environment version from directory name
            local version = nil
            if name:match("1%.8") or name:match("8%.") then version = "JavaSE-1.8"
            elseif name:match("11%.") then version = "JavaSE-11"
            elseif name:match("17%.") then version = "JavaSE-17"
            elseif name:match("21%.") then version = "JavaSE-21"
            end
            
            -- Ensure it's a valid JDK with a java binary, and don't load duplicate versions
            if version and vim.fn.executable(full_path .. "/bin/java") == 1 then
              if not found[version] then
                found[version] = true
                table.insert(runtimes, {
                  name = version,
                  path = full_path,
                })
              end
            end
          end
        end
      end
    end
  end
  return runtimes
end

local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
local workspace_dir = vim.fn.stdpath('data') .. '/site/java/workspace-root/' .. project_name

local jdtls_java_home = nil
local all_runtimes = get_runtimes()
for _, runtime in ipairs(all_runtimes) do
  if runtime.name:match("21") or runtime.name:match("25") then
    jdtls_java_home = runtime.path
    if runtime.name:match("21") then break end -- Prefer 21 over experimental
  end
end

local cmd = { 'jdtls', '-data', workspace_dir }
if jdtls_java_home then
  -- JDTLS requires Java 21+ to run, so we force JAVA_HOME for the server process
  cmd = { 'env', 'JAVA_HOME=' .. jdtls_java_home, 'jdtls', '-data', workspace_dir }
end

local config = {
  -- The command that starts the language server
  -- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
  cmd = cmd,

  -- This is the default if not provided, you can remove it. Or adjust as needed.
  -- One dedicated LSP server & client will be started per unique root_dir
  root_dir = require('jdtls.setup').find_root({'.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle'}),

  -- Here you can configure eclipse.jdt.ls specific settings
  -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
  -- for a list of options
  settings = {
    java = {
      configuration = {
        runtimes = all_runtimes,
      },
      eclipse = {
        downloadSources = true,
      },
      maven = {
        downloadSources = true,
      },
      implementationsCodeLens = {
        enabled = true,
      },
      referencesCodeLens = {
        enabled = true,
      },
      references = {
        includeDecompiledSources = true,
      },
      inlayHints = {
        parameterNames = {
          enabled = 'all', -- literals, all, none
        },
      },
      format = {
        enabled = true,
      },
    },
  },

  init_options = {
    bundles = bundles,
    extendedClientCapabilities = jdtls.extendedClientCapabilities,
  },
}

-- Attach LSP keymaps exactly like we do in lsp.lua
config.on_attach = function(client, bufnr)
  -- Delegate formatting to our conform.lua setup
  client.server_capabilities.documentFormattingProvider = false
  client.server_capabilities.documentRangeFormattingProvider = false

  -- Call the existing on_attach from lsp.lua if we stored it, or just let LSPAttach autocmd handle it.
  -- The LspAttach autocmd in `lua/plugins/lsp.lua` will naturally catch this!
  -- We just need to load jdtls specifically.
end

-- This starts a new client & server,
-- or attaches to an existing client & server depending on the `root_dir`.
jdtls.start_or_attach(config)
