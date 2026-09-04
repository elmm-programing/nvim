return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = {
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
        "ts_ls",
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
      -- Enable servers from nvim-lspconfig after vim.lsp.config() runs
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
        virtual_text = { spacing = 4, prefix = "●" },
        float = { source = "always", border = "rounded", header = "", prefix = "" },
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
            end, vim.tbl_extend("force", opts, { desc = "Find references" }))
            vim.keymap.set("n", "gi", function()
              require("telescope.builtin").lsp_implementations({ reuse_win = true })
            end, vim.tbl_extend("force", opts, { desc = "Go to implementation" }))
            vim.keymap.set("n", "gy", function()
              require("telescope.builtin").lsp_type_definitions({ reuse_win = true })
            end, vim.tbl_extend("force", opts, { desc = "Go to type definition" }))
            vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover" }))
            vim.keymap.set("n", "gK", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Signature help" }))
            vim.keymap.set("i", "<C-s>", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Signature help" }))
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
            ts_ls = true,
            volar = true,
            vue_ls = true,
            jdtls = true,
            rust_analyzer = true,
          }
          if client and client.server_capabilities.inlayHintProvider and hint_servers[client.name] then
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
          end
        end,
      })

      vim.lsp.config("gopls", {
        capabilities = capabilities,
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

      vim.lsp.config("ts_ls", {
        capabilities = capabilities,
        filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
        settings = {
          typescript = {
            inlayHints = {
              parameterNames = { enabled = "all" },
              parameterTypes = { enabled = true },
              variableTypes = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
            },
            preferences = { includePackageJsonAutoImports = "auto" },
          },
          javascript = {
            inlayHints = {
              parameterNames = { enabled = "literals" },
              parameterTypes = { enabled = true },
              variableTypes = { enabled = true },
            },
          },
        },
      })

      -- Volar only on .vue; ts_ls handles standalone TS/JS
      vim.lsp.config("volar", {
        capabilities = capabilities,
        filetypes = { "vue" },
        init_options = {
          typescript = {
            tsdk = vim.fn.stdpath("data") .. "/mason/packages/typescript-language-server/node_modules/typescript/lib",
          },
          vue = { hybridMode = false },
        },
        settings = {
          vue = { complete = { tagCasing = "kebab" } },
        },
      })

      vim.lsp.config("lua_ls", {
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
        json_settings.json.schemas = schemastore.json.schemas()
        yaml_settings.yaml.schemas = schemastore.yaml.schemas()
      end
      vim.lsp.config("jsonls", {
        capabilities = capabilities,
        settings = json_settings,
      })
      vim.lsp.config("yamlls", {
        capabilities = capabilities,
        settings = yaml_settings,
      })

      vim.lsp.config("tailwindcss", { capabilities = capabilities })
      vim.lsp.config("html", {
        capabilities = capabilities,
        filetypes = { "html" },
      })
      vim.lsp.config("cssls", { capabilities = capabilities })
      vim.lsp.config("emmet_ls", {
        capabilities = capabilities,
        filetypes = { "html", "css", "scss", "javascriptreact", "typescriptreact", "vue" },
      })
      vim.lsp.config("dockerls", { capabilities = capabilities })
      vim.lsp.config("bashls", { capabilities = capabilities })

      -- jdtls is started only by nvim-jdtls
      vim.lsp.enable({
        "gopls",
        "ts_ls",
        "volar",
        "lua_ls",
        "jsonls",
        "tailwindcss",
        "html",
        "cssls",
        "emmet_ls",
        "yamlls",
        "dockerls",
        "bashls",
      })
    end,
  },
}
