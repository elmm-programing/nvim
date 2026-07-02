return {
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    config = function()
      local capabilities = require("blink.cmp").get_lsp_capabilities(vim.lsp.protocol.make_client_capabilities())
      
      local config = {
        cmd = { vim.fn.stdpath("data") .. "/mason/packages/jdtls/jdtls" },
        root_dir = vim.fs.dirname(vim.fs.find({ "gradlew", ".git", "pom.xml" }, { upward = true })[1]),
        capabilities = capabilities,
        settings = {
          java = {
            eclipse = { downloadSources = true },
            configuration = { updateBuildConfiguration = "automatic" },
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
      }
      
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "java",
        callback = function()
          require("jdtls").start_or_attach(config)
        end,
      })
    end,
  },
}
