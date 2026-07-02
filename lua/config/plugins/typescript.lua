return {
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
}
