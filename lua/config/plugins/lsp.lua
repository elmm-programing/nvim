return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = {
      registries = {
        -- Listed first so it overrides the GitHub registry copy of vue-language-server.
        "lua:config.mason.registry",
        "github:mason-org/mason-registry",
      },
      npm = {
        -- Work networks often serve a stale @vue packument, so npm reports
        -- ETARGET for @vue/language-core even though the version exists.
        install_args = {
          "--registry",
          "https://registry.npmjs.org/",
          "--prefer-online",
        },
      },
      ui = {
        border = "rounded",
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    },
  },

  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        "gopls",
        "vtsls",
        "jdtls",
        "lua_ls",
        "yamlls",
        "jsonls",
        "dockerls",
        "bashls",
        "tailwindcss",
        "html",
        "cssls",
        "emmet_ls",
      },
      -- Servers are enabled in the nvim-lspconfig config below.
      automatic_enable = false,
    },
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      { "j-hui/fidget.nvim", opts = {} },
      "SmiteshP/nvim-navic",
      "b0o/schemastore.nvim",
    },
    config = function()
      -- vim.lsp.config exists on Neovim 0.11+. Older Neovim uses lspconfig's setup().
      local function configure_server(name, opts)
        if vim.lsp.config then
          vim.lsp.config(name, opts)
          return
        end
        local ok = pcall(require, "lspconfig.configs." .. name)
        if not ok then
          return false
        end
        require("lspconfig")[name].setup(opts)
        return true
      end

      -- nvim-lspconfig still calls this server "volar" on Neovim 0.10.
      local vue_server = "vue_ls"
      if not vim.lsp.config then
        local has_vue = pcall(require, "lspconfig.configs.vue_ls")
        local has_volar = pcall(require, "lspconfig.configs.volar")
        if not has_vue and has_volar then
          vue_server = "volar"
        elseif not has_vue then
          vue_server = nil
        end
      end

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_blink, blink = pcall(require, "blink.cmp")
      if ok_blink then
        capabilities = vim.tbl_deep_extend("force", capabilities, blink.get_lsp_capabilities())
      end
      capabilities.textDocument.foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      }

      local signs = { Error = "", Warn = "", Hint = "", Info = "" }
      vim.diagnostic.config({
        virtual_text = { spacing = 4, prefix = "●", source = "if_many" },
        float = { source = "if_many", border = "rounded", header = "", prefix = "" },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = signs.Error,
            [vim.diagnostic.severity.WARN] = signs.Warn,
            [vim.diagnostic.severity.HINT] = signs.Hint,
            [vim.diagnostic.severity.INFO] = signs.Info,
          },
        },
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      -- Neovim 0.11+ maps grn/gra/grr/gri/grt/grx, so `gr` is a prefix and waits
      -- on timeoutlen / which-key instead of jumping to references.
      for _, lhs in ipairs({ "grr", "grn", "gra", "gri", "grt", "grx" }) do
        pcall(vim.keymap.del, "n", lhs)
      end
      pcall(vim.keymap.del, { "v", "x" }, "gra")

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("LspConfig", { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          local opts = { buffer = bufnr, silent = true }

          if client and client.server_capabilities.documentSymbolProvider then
            local navic_ok, navic = pcall(require, "nvim-navic")
            if navic_ok then
              navic.attach(client, bufnr)
            end
          end

          if not vim.b[bufnr].lsp_keys then
            vim.b[bufnr].lsp_keys = true
            vim.keymap.set("n", "gd", function()
              require("telescope.builtin").lsp_definitions({ reuse_win = true })
            end, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
            vim.keymap.set("n", "gD", function()
              require("telescope.builtin").lsp_declarations({ reuse_win = true })
            end, vim.tbl_extend("force", opts, { desc = "Go to declaration" }))
            vim.keymap.set("n", "gr", function()
              require("telescope.builtin").lsp_references({ include_current_line = false })
            end, vim.tbl_extend("force", opts, { desc = "Find references", nowait = true }))
            vim.keymap.set("n", "gi", function()
              require("telescope.builtin").lsp_implementations({ reuse_win = true })
            end, vim.tbl_extend("force", opts, { desc = "Go to implementation" }))
            vim.keymap.set("n", "gy", function()
              require("telescope.builtin").lsp_type_definitions({ reuse_win = true })
            end, vim.tbl_extend("force", opts, { desc = "Go to type definition" }))
            vim.keymap.set("n", "K", function()
              vim.lsp.buf.hover({ border = "rounded", silent = true })
            end, vim.tbl_extend("force", opts, { desc = "Hover" }))
            vim.keymap.set("n", "gK", function()
              vim.lsp.buf.signature_help({ border = "rounded" })
            end, vim.tbl_extend("force", opts, { desc = "Signature help" }))
            vim.keymap.set("i", "<C-s>", function()
              vim.lsp.buf.signature_help({ border = "rounded" })
            end, vim.tbl_extend("force", opts, { desc = "Signature help" }))
            vim.keymap.set("n", "<leader>cI", "<cmd>LspInfo<CR>", vim.tbl_extend("force", opts, { desc = "LSP Info" }))
            vim.keymap.set({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code Action" }))
            vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename" }))
            vim.keymap.set("n", "<leader>cA", function()
              vim.lsp.buf.code_action({
                context = { only = { "source" } },
                apply = true,
              })
            end, vim.tbl_extend("force", opts, { desc = "Source Action" }))
            vim.keymap.set("n", "<leader>co", function()
              vim.lsp.buf.code_action({
                context = { only = { "source.organizeImports" } },
                apply = true,
              })
            end, vim.tbl_extend("force", opts, { desc = "Organize Imports" }))
            vim.keymap.set("n", "<leader>ss", function()
              require("telescope.builtin").lsp_document_symbols({ symbol_width = 60 })
            end, vim.tbl_extend("force", opts, { desc = "LSP Symbols" }))
            vim.keymap.set("n", "<leader>sS", function()
              require("telescope.builtin").lsp_workspace_symbols({ symbol_width = 60 })
            end, vim.tbl_extend("force", opts, { desc = "LSP Workspace Symbols" }))
            vim.keymap.set("n", "<leader>wd", function()
              require("telescope.builtin").diagnostics({ bufnr = 0 })
            end, vim.tbl_extend("force", opts, { desc = "Buffer diagnostics" }))
            vim.keymap.set("n", "<leader>wD", function()
              require("telescope.builtin").diagnostics()
            end, vim.tbl_extend("force", opts, { desc = "All diagnostics" }))
            vim.keymap.set("n", "<leader>uh", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
            end, vim.tbl_extend("force", opts, { desc = "Toggle inlay hints" }))
          end

          if client and client.server_capabilities.codeLensProvider then
            pcall(vim.lsp.codelens.refresh, { bufnr = bufnr })
            if not vim.b[bufnr].codelens_au then
              vim.b[bufnr].codelens_au = true
              vim.keymap.set("n", "<leader>cc", function()
                vim.lsp.codelens.run()
              end, vim.tbl_extend("force", opts, { desc = "Run Codelens" }))
              vim.keymap.set("n", "<leader>cC", function()
                vim.lsp.codelens.refresh({ bufnr = bufnr })
              end, vim.tbl_extend("force", opts, { desc = "Refresh Codelens" }))
              vim.api.nvim_create_autocmd({ "InsertLeave", "BufWritePost" }, {
                buffer = bufnr,
                callback = function()
                  pcall(vim.lsp.codelens.refresh, { bufnr = bufnr })
                end,
              })
            end
          end

          local hint_servers = {
            gopls = true,
            vtsls = true,
            vue_ls = true,
            volar = true,
            jdtls = true,
            rust_analyzer = true,
          }
          if client and client.server_capabilities.inlayHintProvider and hint_servers[client.name] then
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
          end
        end,
      })

      configure_server("gopls", {
        capabilities = capabilities,
        filetypes = { "go", "gomod", "gowork" },
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
              unusedwrite = true,
              useany = true,
              shadow = true,
            },
            staticcheck = true,
            gofumpt = true,
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              compositeLiteralTypes = true,
              constantValues = true,
              functionTypeParameters = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
          },
        },
      })

      local vue_language_server = vim.fn.stdpath("data")
        .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"
      local function mason_typescript_lib()
        local candidates = {
          vim.fn.stdpath("data") .. "/mason/packages/vtsls/node_modules/typescript/lib",
          vim.fn.stdpath("data") .. "/mason/packages/vue-language-server/node_modules/typescript/lib",
        }
        for _, path in ipairs(candidates) do
          if vim.fn.isdirectory(path) == 1 then
            return path
          end
        end
        return candidates[1]
      end
      local function workspace_typescript_lib(root)
        if not root or root == "" then
          return nil
        end
        local lib = root .. "/node_modules/typescript/lib"
        if vim.fn.isdirectory(lib) == 1 then
          return lib
        end
        return nil
      end

      -- vtsls owns JS/TS and .vue (via @vue/typescript-plugin). vue_ls attaches only to .vue.
      configure_server("vtsls", {
        capabilities = capabilities,
        filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact", "vue" },
        settings = {
          vtsls = {
            autoUseWorkspaceTsdk = true,
            enableMoveToFileCodeAction = true,
            tsserver = {
              globalPlugins = {
                {
                  name = "@vue/typescript-plugin",
                  location = vue_language_server,
                  languages = { "vue" },
                  configNamespace = "typescript",
                  enableForWorkspaceTypeScriptVersions = true,
                },
              },
            },
          },
          typescript = {
            updateImportsOnFileMove = { enabled = "always" },
            preferences = { includePackageJsonAutoImports = "auto" },
            inlayHints = {
              parameterNames = { enabled = "literals" },
              parameterTypes = { enabled = false },
              variableTypes = { enabled = false },
              propertyDeclarationTypes = { enabled = false },
              functionLikeReturnTypes = { enabled = false },
            },
          },
          javascript = {
            updateImportsOnFileMove = { enabled = "always" },
            inlayHints = {
              parameterNames = { enabled = "literals" },
              parameterTypes = { enabled = false },
              variableTypes = { enabled = false },
            },
          },
        },
      })

      if vue_server then
      configure_server(vue_server, {
        capabilities = capabilities,
        filetypes = { "vue" },
        init_options = {
          vue = { hybridMode = true },
          typescript = { tsdk = mason_typescript_lib() },
        },
        settings = {
          vue = { complete = { tagCasing = "kebab" } },
        },
        before_init = function(_, config)
          local tsdk = workspace_typescript_lib(config.root_dir) or mason_typescript_lib()
          config.init_options = vim.tbl_deep_extend("force", config.init_options or {}, {
            typescript = { tsdk = tsdk },
            vue = { hybridMode = true },
          })
        end,
        on_init = function(client)
          client.handlers["tsserver/request"] = function(_, result, context)
            local get_clients = vim.lsp.get_clients or vim.lsp.get_active_clients
            local ts_clients = get_clients({ bufnr = context.bufnr, name = "vtsls" })
            if #ts_clients == 0 then
              vim.notify("vue_ls needs vtsls on this buffer", vim.log.levels.ERROR)
              return
            end
            local ts_client = ts_clients[1]
            if not ts_client.exec_cmd or type(result) ~= "table" then
              return
            end
            local param = unpack(result)
            if type(param) ~= "table" then
              return
            end
            local id, command, payload = unpack(param)
            ts_client:exec_cmd({
              title = "vue_request_forward",
              command = "typescript.tsserverRequest",
              arguments = { command, payload },
            }, { bufnr = context.bufnr }, function(_, response)
              local body = response and response.body
              client:notify("tsserver/response", { { id, body } })
            end)
          end
        end,
      })
      end

      configure_server("lua_ls", {
        capabilities = capabilities,
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
            completion = { callSnippet = "Replace" },
          },
        },
      })

      local json_settings = { json = { validate = { enable = true } } }
      local yaml_settings = {
        yaml = {
          format = { enable = false },
          validate = true,
          schemaStore = { enable = false, url = "" },
        },
      }
      local ok_store, schemastore = pcall(require, "schemastore")
      if ok_store then
        json_settings.json.schemas = schemastore.json.schemas({
          select = {
            "package.json",
            "tsconfig.json",
            ".eslintrc",
            "prettierrc.json",
            "jsconfig.json",
          },
        })
        yaml_settings.yaml.schemas = schemastore.yaml.schemas({
          select = {
            "GitHub Workflow",
            "GitHub Action",
            "docker-compose.yml",
          },
        })
      end
      configure_server("jsonls", {
        capabilities = capabilities,
        filetypes = { "json", "jsonc" },
        settings = json_settings,
      })
      configure_server("yamlls", {
        capabilities = capabilities,
        filetypes = { "yaml", "yml" },
        settings = yaml_settings,
      })

      configure_server("tailwindcss", {
        capabilities = capabilities,
        filetypes = {
          "html",
          "css",
          "scss",
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
          "vue",
        },
      })
      configure_server("html", {
        capabilities = capabilities,
        filetypes = { "html" },
      })
      configure_server("cssls", { capabilities = capabilities })
      configure_server("emmet_ls", {
        capabilities = capabilities,
        filetypes = { "html", "css", "scss", "javascriptreact", "typescriptreact", "vue" },
      })
      configure_server("dockerls", { capabilities = capabilities })
      configure_server("bashls", { capabilities = capabilities })

      -- jdtls is started only by nvim-jdtls.
      -- setup() already starts servers on Neovim before 0.11.
      if vim.lsp.enable then
        local servers = {
          "gopls",
          "vtsls",
          "lua_ls",
          "jsonls",
          "tailwindcss",
          "html",
          "cssls",
          "emmet_ls",
          "yamlls",
          "dockerls",
          "bashls",
        }
        if vue_server then
          table.insert(servers, 3, vue_server)
        end
        vim.lsp.enable(servers)
      end
    end,
  },
}
