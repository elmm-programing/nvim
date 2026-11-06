return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo", "ToggleFormatter" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        mode = { "n", "v" },
        desc = "Format",
      },
    },
    opts = {
      formatters_by_ft = {
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        vue = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        go = { "goimports", "gofumpt" },
        java = { "google-java-format" },
        lua = { "stylua" },
        rust = { "rustfmt" },
      },
      format_on_save = function(bufnr)
        if vim.b[bufnr].disable_format_on_save or vim.b[bufnr].large_file or vim.bo[bufnr].filetype == "bigfile" then
          return
        end
        return { timeout_ms = 2000, lsp_format = "fallback" }
      end,
    },
    config = function(_, opts)
      require("conform").setup(opts)
      vim.api.nvim_create_user_command("ToggleFormatter", function()
        local bufnr = vim.api.nvim_get_current_buf()
        vim.b[bufnr].disable_format_on_save = not vim.b[bufnr].disable_format_on_save
        vim.notify(
          vim.b[bufnr].disable_format_on_save and "Format on save disabled" or "Format on save enabled",
          vim.log.levels.INFO
        )
      end, { desc = "Toggle format on save for this buffer" })
    end,
  },

  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        vue = { "eslint_d" },
      }

      local eslint_roots = {
        "eslint.config.js",
        "eslint.config.mjs",
        "eslint.config.cjs",
        "eslint.config.ts",
        ".eslintrc",
        ".eslintrc.js",
        ".eslintrc.cjs",
        ".eslintrc.json",
        ".eslintrc.yml",
        ".eslintrc.yaml",
      }

      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
        group = vim.api.nvim_create_augroup("NvimLint", { clear = true }),
        callback = function(args)
          if vim.b[args.buf].large_file or vim.bo[args.buf].filetype == "bigfile" then
            return
          end
          local ft = vim.bo[args.buf].filetype
          if not lint.linters_by_ft[ft] then
            return
          end
          if vim.fs.root(args.buf, eslint_roots) then
            lint.try_lint()
          end
        end,
      })
    end,
  },
}
