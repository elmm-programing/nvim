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
      automatic_installation = true,
      automatic_enable = {
        exclude = { "jdtls", "rust_analyzer" },
      },
    },
    config = function(_, opts)
      require("mason-lspconfig").setup(opts)
      
      -- Manually ensure volar is installed (not in mason-lspconfig ensure list)
      vim.defer_fn(function()
        local registry = require("mason-registry")
        if not registry.is_installed("vue-language-server") then
          vim.notify("Installing vue-language-server (volar)...", vim.log.levels.INFO)
          local ok, err = pcall(function()
            registry.get_package("vue-language-server"):install()
          end)
          if not ok then
            vim.notify("Failed to install vue-language-server: " .. tostring(err), vim.log.levels.WARN)
          end
        end
      end, 1000)
    end,
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      { "j-hui/fidget.nvim", opts = {} },
      { "SmiteshP/nvim-navic", opts = { highlight = true } },
    },
    config = function()
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      
      -- Add blink.cmp capabilities if available
      local ok, blink = pcall(require, "blink.cmp")
      if ok then
        capabilities = vim.tbl_deep_extend("force", capabilities, blink.get_lsp_capabilities())
      end

      -- Enable folding support
      capabilities.textDocument.foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      }

      -- Diagnostic signs
      local signs = {
        Error = " ",
        Warn = " ",
        Hint = " ",
        Info = " ",
      }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end

      vim.diagnostic.config({
        virtual_text = { spacing = 4, prefix = "●" },
        float = {
          source = "always",
          border = "rounded",
          header = "",
          prefix = "",
        },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      -- LSP attach callback with navic support
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("LspConfig", { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          local opts = { buffer = bufnr, silent = true }
          
          -- Attach navic for breadcrumbs (if supported)
          if client and client.server_capabilities.documentSymbolProvider then
            local navic_ok, navic = pcall(require, "nvim-navic")
            if navic_ok then
              navic.attach(client, bufnr)
            end
          end

          -- Telescope-based LSP keymaps
          local tb = require("telescope.builtin")
          
          vim.keymap.set("n", "gd", function() tb.lsp_definitions({ jump_type = "never", reuse_win = true }) end, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
          vim.keymap.set("n", "gD", function() tb.lsp_declarations({ jump_type = "never", reuse_win = true }) end, vim.tbl_extend("force", opts, { desc = "Go to declaration" }))
          vim.keymap.set("n", "gr", function() tb.lsp_references({ include_current_line = false }) end, vim.tbl_extend("force", opts, { desc = "Find references" }))
          vim.keymap.set("n", "gi", function() tb.lsp_implementations({ jump_type = "never", reuse_win = true }) end, vim.tbl_extend("force", opts, { desc = "Go to implementation" }))
          vim.keymap.set("n", "gy", function() tb.lsp_type_definitions({ jump_type = "never", reuse_win = true }) end, vim.tbl_extend("force", opts, { desc = "Go to type definition" }))
          vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover" }))
          vim.keymap.set("n", "gK", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Signature help" }))
          vim.keymap.set("i", "<C-s>", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Signature help" }))
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename" }))
          vim.keymap.set({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code Action" }))
          vim.keymap.set("n", "<leader>cf", function() vim.lsp.buf.format({ async = true }) end, vim.tbl_extend("force", opts, { desc = "Format" }))
          vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename" }))
          vim.keymap.set("n", "<leader>cR", function() vim.lsp.buf.rename(nil, { rename_file = true }) end, vim.tbl_extend("force", opts, { desc = "Rename File" }))
          vim.keymap.set("n", "<leader>cA", function()
            vim.lsp.buf.code_action({ filter = function(a) return a.isSourceAction end, apply = true })
          end, vim.tbl_extend("force", opts, { desc = "Source Action" }))
          vim.keymap.set("n", "<leader>co", function()
            vim.lsp.buf.code_action({
              filter = function(a)
                return a.kind and (a.kind:match("source") or a.kind:match("organize") or a.kind:match("import")) ~= nil
              end,
              apply = true,
            })
          end, vim.tbl_extend("force", opts, { desc = "Organize Imports" }))
          vim.keymap.set("n", "<leader>ss", function() tb.lsp_document_symbols({ symbol_width = 60 }) end, vim.tbl_extend("force", opts, { desc = "LSP Symbols" }))
          vim.keymap.set("n", "<leader>sS", function() tb.lsp_workspace_symbols({ symbol_width = 60 }) end, vim.tbl_extend("force", opts, { desc = "LSP Workspace Symbols" }))
          vim.keymap.set("n", "<leader>ds", function() tb.lsp_document_symbols() end, vim.tbl_extend("force", opts, { desc = "Document symbols" }))
          vim.keymap.set("n", "<leader>ws", function() tb.lsp_dynamic_workspace_symbols() end, vim.tbl_extend("force", opts, { desc = "Workspace symbols" }))
          vim.keymap.set("n", "<leader>wd", function() tb.diagnostics({ bufnr = 0 }) end, vim.tbl_extend("force", opts, { desc = "Buffer diagnostics" }))
          vim.keymap.set("n", "<leader>wD", function() tb.diagnostics() end, vim.tbl_extend("force", opts, { desc = "All diagnostics" }))
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, vim.tbl_extend("force", opts, { desc = "Prev diagnostic" }))
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, vim.tbl_extend("force", opts, { desc = "Next diagnostic" }))

          -- Codelens setup (if supported by client)
          if client and client.server_capabilities.codeLensProvider then
            vim.lsp.codelens.refresh({ bufnr = bufnr })
            vim.lsp.codelens.display({ bufnr = bufnr })
            vim.keymap.set("n", "<leader>cc", function() vim.lsp.codelens.run({ bufnr = bufnr }) end, vim.tbl_extend("force", opts, { desc = "Run Codelens" }))
            vim.keymap.set("n", "<leader>cC", function()
              vim.lsp.codelens.refresh({ bufnr = bufnr })
              vim.lsp.codelens.display({ bufnr = bufnr })
            end, vim.tbl_extend("force", opts, { desc = "Refresh & Display Codelens" }))
            -- Auto-refresh codelens on changes
            vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "BufWritePost" }, {
              buffer = bufnr,
              callback = function()
                pcall(vim.lsp.codelens.refresh, { bufnr = bufnr })
                pcall(vim.lsp.codelens.display, { bufnr = bufnr })
              end,
            })
          end

          -- Inlay hints toggle
          if client and client.server_capabilities.inlayHintProvider then
            vim.keymap.set("n", "<leader>th", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
            end, vim.tbl_extend("force", opts, { desc = "Toggle inlay hints" }))
          end
        end,
      })

      -- Go
      vim.lsp.config("gopls", {
        capabilities = capabilities,
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
              unusedwrite = true,
              useany = true,
              shadow = true,
              fieldalignment = true,
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

      -- TypeScript (ts_ls for modern projects, vtsls as alternative)
      vim.lsp.config("ts_ls", {
        capabilities = capabilities,
        settings = {
          typescript = {
            inlayHints = {
              parameterNames = { enabled = "all" },
              parameterTypes = { enabled = true },
              variableTypes = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
            },
            preferences = {
              includePackageJsonAutoImports = "auto",
            },
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

      -- Vue (volar with takeover mode for Vue 3 + TypeScript)
      vim.lsp.config("volar", {
        capabilities = capabilities,
        filetypes = { "vue", "typescript", "javascript" },
        init_options = {
          typescript = { 
            tsdk = vim.fn.stdpath("data") .. "/mason/packages/typescript-language-server/node_modules/typescript/lib" 
          },
          vue = {
            hybridMode = false, -- Use volar's built-in TypeScript support
          },
        },
        settings = {
          vue = {
            complete = {
              tagCasing = "kebab",
            },
          },
        },
      })

      -- Lua
      vim.lsp.config("lua_ls", {
        capabilities = capabilities,
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
            telemetry = { enable = false },
            completion = { callSnippet = "Replace" },
          },
        },
      })

      -- Other servers
      vim.lsp.config("tailwindcss", { capabilities = capabilities })
      vim.lsp.config("html", { capabilities = capabilities })
      vim.lsp.config("cssls", { capabilities = capabilities })
      vim.lsp.config("emmet_ls", { capabilities = capabilities })
      vim.lsp.config("yamlls", {
        capabilities = capabilities,
        settings = { yaml = { format = { enable = true } } },
      })
      vim.lsp.config("dockerls", { capabilities = capabilities })
      vim.lsp.config("bashls", { capabilities = capabilities })

      -- jdtls is started by nvim-jdtls; rust-analyzer is started by rustaceanvim.
      vim.lsp.enable({
        "gopls", "ts_ls", "volar", "lua_ls",
        "tailwindcss", "html", "cssls", "emmet_ls",
        "yamlls", "dockerls", "bashls",
      })

      -- :LspInfo command
      vim.api.nvim_create_user_command("LspInfo", function()
        local bufnr = vim.api.nvim_get_current_buf()
        local clients = vim.lsp.get_clients({ bufnr = bufnr })
        local lines = { "LSP clients attached to buffer " .. bufnr .. " (" .. vim.bo[bufnr].filetype .. "):" }
        if #clients == 0 then
          lines[#lines + 1] = "  (none)"
        else
          for _, c in ipairs(clients) do
            lines[#lines + 1] = ("  • %s (id=%d, root=%s)"):format(c.name, c.id, c.root_dir or "(no root)")
          end
        end
        vim.api.nvim_echo(
          vim.tbl_map(function(l) return { l .. "\n", "Normal" } end, lines),
          true,
          {}
        )
      end, { desc = "Show LSP clients attached to current buffer" })
    end,
  },
}