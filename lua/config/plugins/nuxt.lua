return {
  -- Nuxt-specific utilities
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
  },

  -- Auto-detect Nuxt projects and set up properly
  {
    "nvim-lua/plenary.nvim",
    lazy = true,
  },

  -- Nuxt file type detection
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        volar = {
          filetypes = { "vue", "javascript", "typescript", "javascriptreact", "typescriptreact" },
          init_options = {
            typescript = {
              tsdk = vim.fn.stdpath("data") .. "/mason/packages/typescript-language-server/node_modules/typescript/lib",
            },
          },
        },
      },
    },
  },

  -- Nuxt-specific keymaps and commands
  {
    "folke/which-key.nvim",
    opts = {
      defaults = {
        ["<leader>v"] = { name = "+vue/nuxt" },
        ["<leader>n"] = { name = "+nuxt" },
      },
    },
  },

  -- Nuxt component auto-completion helper
  {
    "hrsh7th/nvim-cmp",
    optional = true,
    opts = function(_, opts)
      local cmp = require("cmp")
      
      -- Add Nuxt component source
      opts.sources = opts.sources or {}
      table.insert(opts.sources, {
        name = "nvim_lsp",
        priority = 100,
      })
      
      return opts
    end,
  },

  -- Better Vue/Nuxt support with takeover mode
  {
    "pmizio/typescript-tools.nvim",
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact", "vue" },
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    opts = {
      settings = {
        expose_as_code_action = "all",
        complete_function_calls = true,
        tsserver_file_preferences = {
          includeInlayParameterNameHints = "all",
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHints = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayEnumMemberValueHints = true,
        },
        tsserver_format_options = {
          allowIncompleteCompletions = false,
          allowRenameOfImportPath = true,
          insertSpaceAfterCommaDelimiter = true,
          insertSpaceAfterConstructor = true,
          insertSpaceAfterFunctionKeywordForAnonymousFunctions = true,
          insertSpaceAfterKeywordsInNewExpression = true,
          insertSpaceAfterOpeningAndBeforeClosingNonemptyBraces = true,
          insertSpaceAfterSemicolonInForStatements = true,
          insertSpaceBeforeAndAfterBinaryOperators = true,
          insertSpaceBeforeFunctionParenthesis = false,
          placeOpenBraceOnNewLineForControlBlocks = false,
          placeOpenBraceOnNewLineForFunctions = false,
          semicolons = "insert",
          trailingCommas = "remove",
          indentSize = 2,
          tabSize = 2,
        },
      },
    },
    config = function(_, opts)
      require("typescript-tools").setup(opts)
      
      -- Vue takeover mode for TypeScript in Vue files
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = { "*.vue" },
        callback = function()
          local bufnr = vim.api.nvim_get_current_buf()
          vim.treesitter.start(bufnr, "vue")
        end,
      })
    end,
  },

  -- Auto-detect Nuxt project and configure
  {
    "nvim-lua/plenary.nvim",
    lazy = true,
    config = function()
      -- Detect if we're in a Nuxt project
      local function is_nuxt_project()
        local cwd = vim.fn.getcwd()
        return vim.fn.filereadable(cwd .. "/nuxt.config.ts") == 1 or
               vim.fn.filereadable(cwd .. "/nuxt.config.js") == 1
      end

      -- Set up Nuxt-specific settings
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
        callback = function()
          if is_nuxt_project() then
            -- Set up Nuxt-specific settings
            vim.bo.filetype = "vue"
            
            -- Add Nuxt auto-imports
            vim.g.vue_pre_processors = "detect_on_enter"
            
            -- Set up Nuxt-specific path aliases
            vim.g.nuxt_path_aliases = {
              ["~"] = vim.fn.getcwd(),
              ["@"] = vim.fn.getcwd(),
              ["~~"] = vim.fn.getcwd(),
              ["@@"] = vim.fn.getcwd(),
            }
          end
        end,
      })
    end,
  },
}
