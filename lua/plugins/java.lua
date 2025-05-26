return {
  {
    "mfussenegger/nvim-jdtls",
    dependencies = { "folke/which-key.nvim" },
    ft = java_filetypes, -- Assuming java_filetypes is defined elsewhere or you define it here
    opts = function()
      local cmd = { vim.fn.exepath("jdtls") }
      -- Note: The original opts.dap and opts.test are used in the config function below.
      -- Ensure they are present or provide default values if necessary.
      -- For simplicity, this example assumes 'opts' passed to the config function
      -- will have 'dap' and 'test' fields from the plugin's default opts or LazyVim's setup.

      -- If lombok.jar is managed by mason for jdtls itself (not the debug adapter),
      -- this part of cmd setup can remain.
      if LazyVim.has("mason.nvim") then
        local mason_registry = require("mason-registry")
        local jdtls_pkg = mason_registry.get_package("jdtls")
        if jdtls_pkg and jdtls_pkg:is_installed() then
          local lombok_jar = jdtls_pkg:get_install_path() .. "/lombok.jar"
          if vim.uv.fs_stat(lombok_jar) then
            table.insert(cmd, string.format("--jvm-arg=-javaagent:%s", lombok_jar))
          end
        end
      end

      return {
        root_dir = LazyVim.lsp.get_raw_config("jdtls").default_config.root_dir,
        project_name = function(root_dir)
          return root_dir and vim.fs.basename(root_dir)
        end,
        jdtls_config_dir = function(project_name)
          return vim.fn.stdpath("cache") .. "/jdtls/" .. project_name .. "/config"
        end,
        jdtls_workspace_dir = function(project_name)
          return vim.fn.stdpath("cache") .. "/jdtls/" .. project_name .. "/workspace"
        end,
        cmd = cmd, -- Base command for jdtls
        full_cmd = function(opts_inner_scope) -- Renamed to avoid conflict
          local fname = vim.api.nvim_buf_get_name(0)
          local root_dir = opts_inner_scope.root_dir(fname)
          local project_name = opts_inner_scope.project_name(root_dir)
          local current_cmd = vim.deepcopy(opts_inner_scope.cmd) -- Use the cmd from current scope
          if project_name then
            vim.list_extend(current_cmd, {
              "-configuration",
              opts_inner_scope.jdtls_config_dir(project_name),
              "-data",
              opts_inner_scope.jdtls_workspace_dir(project_name),
            })
          end
          return current_cmd
        end,
        dap = { hotcodereplace = "auto", config_overrides = {} },
        dap_main = {},
        test = true, -- Assuming you want Java test capabilities
        settings = {
          java = {
            configuration = {
              runtimes = {
                {
                  name = "JavaSE-21", -- For projects targeting Java 23
                  path = vim.fn.expand("~/.sdkman/candidates/java/21.0.4-tem/"), -- JDK 23 root (ensure 'current' points here)
                },
                {
                  name = "JavaSE-17", -- For projects targeting Java 17
                  -- IMPORTANT: Replace with the actual path to your SDKMAN Java 17 root
                  path = vim.fn.expand("~/.sdkman/candidates/java/17.0.12-tem/"),
                },
                -- {
                --   name = "JavaSE-11", -- For projects targeting Java 11
                --   -- IMPORTANT: Replace with the actual path to your SDKMAN Java 11 root
                --   path = vim.fn.expand("~/.sdkman/candidates/java/YOUR_JAVA_11_VERSION_DIR/"),
                -- },
                -- Add more runtimes if needed
              },
            },
            inlayHints = {
              parameterNames = {
                enabled = "all",
              },
            },
          },
        },
        -- Placeholder for any jdtls-specific options from the original plugin spec, if any
        jdtls = {},
      }
    end,
    config = function(_, opts)
      -- Find the extra bundles that should be passed on the jdtls command-line
      local bundles = {} ---@type string[]

      if opts.dap and LazyVim.has("nvim-dap") then
        -- Use the local java-debug-adapter JAR
        local local_java_debug_jar = vim.fn.stdpath("config")
          .. "/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-0.53.2.jar"

        if vim.uv.fs_stat(local_java_debug_jar) then
          table.insert(bundles, local_java_debug_jar)
          vim.notify("Using local java-debug-adapter: " .. local_java_debug_jar, vim.log.levels.INFO)
        else
          vim.notify(
            "Local java-debug-adapter JAR not found at: "
              .. local_java_debug_jar
              .. ". Debugging capabilities might be affected.",
            vim.log.levels.ERROR
          )
        end

        -- Handle java-test JARs if still needed (e.g., from Mason)
        if opts.test and LazyVim.has("mason.nvim") then
          local mason_registry = require("mason-registry")
          if mason_registry.is_installed("java-test") then
            local java_test_pkg = mason_registry.get_package("java-test")
            local java_test_path = java_test_pkg:get_install_path()
            if java_test_path then
              local java_test_jar_pattern = java_test_path .. "/extension/server/*.jar"
              local test_jars_str = vim.fn.glob(java_test_jar_pattern)
              if test_jars_str ~= "" then
                for _, bundle_path in ipairs(vim.split(test_jars_str, "\n")) do
                  if bundle_path ~= "" then
                    table.insert(bundles, bundle_path)
                  end
                end
              end
            else
              vim.notify("Could not get install path for java-test from Mason.", vim.log.levels.WARN)
            end
          end
        end
      end

      local function extend_or_override(base, override)
        local extended = vim.deepcopy(base)
        if override then
          for k, v in pairs(override) do
            extended[k] = v
          end
        end
        return extended
      end

      local function attach_jdtls()
        local fname = vim.api.nvim_buf_get_name(0)

        local jdtls_config_for_attach = extend_or_override({
          cmd = opts.full_cmd(opts),
          root_dir = opts.root_dir(fname),
          init_options = {
            bundles = bundles, -- This 'bundles' table now includes your local JAR
          },
          settings = opts.settings,
          capabilities = LazyVim.has("cmp-nvim-lsp") and require("cmp_nvim_lsp").default_capabilities() or nil,
        }, opts.jdtls) -- opts.jdtls allows further user overrides from their LazyVim config

        require("jdtls").start_or_attach(jdtls_config_for_attach)
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "java", -- Assuming java_filetypes includes "java"
        callback = attach_jdtls,
      })

      attach_jdtls() -- Call it once for the initial buffer

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.name == "jdtls" then
            local wk = require("which-key")
            wk.add({
              {
                mode = "n",
                buffer = args.buf,
                { "<leader>cx", group = "extract" },
                { "<leader>cxv", require("jdtls").extract_variable_all, desc = "Extract Variable (all occurrences)" },
                { "<leader>cxc", require("jdtls").extract_constant, desc = "Extract Constant" },
                { "<leader>cgs", require("jdtls").super_implementation, desc = "Goto Super Implementation" },
                { "<leader>cgS", require("jdtls.tests").goto_subjects, desc = "Goto Test Subjects" },
                { "<leader>co", require("jdtls").organize_imports, desc = "Organize Imports" },
              },
            })
            wk.add({
              {
                mode = "v",
                buffer = args.buf,
                { "<leader>cx", group = "extract" },
                {
                  "<leader>cxm",
                  function()
                    require("jdtls").extract_method(true)
                  end,
                  desc = "Extract Method",
                },
                {
                  "<leader>cxv",
                  function()
                    require("jdtls").extract_variable_all(true)
                  end,
                  desc = "Extract Variable (all occurrences)",
                },
                {
                  "<leader>cxc",
                  function()
                    require("jdtls").extract_constant(true)
                  end,
                  desc = "Extract Constant",
                },
              },
            })

            if opts.dap and LazyVim.has("nvim-dap") then
              require("jdtls").setup_dap(opts.dap)
              if opts.dap_main then
                require("jdtls.dap").setup_dap_main_class_configs(opts.dap_main)
              end

              if opts.test then
                wk.add({
                  {
                    mode = "n",
                    buffer = args.buf,
                    { "<leader>t", group = "test" },
                    {
                      "<leader>tt",
                      function()
                        require("jdtls.dap").test_class({
                          config_overrides = type(opts.test) ~= "boolean" and opts.test.config_overrides or nil,
                        })
                      end,
                      desc = "Run All Tests in Class",
                    },
                    {
                      "<leader>tr",
                      function()
                        require("jdtls.dap").test_nearest_method({
                          config_overrides = type(opts.test) ~= "boolean" and opts.test.config_overrides or nil,
                        })
                      end,
                      desc = "Run Nearest Test Method",
                    },
                    {
                      "<leader>tT",
                      function()
                        require("jdtls.dap").pick_test({
                          config_overrides = type(opts.test) ~= "boolean" and opts.test.config_overrides or nil,
                        })
                      end,
                      desc = "Run Test (Pick)",
                    },
                  },
                })
              end
            end

            if opts.on_attach then
              opts.on_attach(args)
            end
          end
        end,
      })
    end,
  },
}
