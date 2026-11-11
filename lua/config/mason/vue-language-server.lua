-- Mason's registry installs @vue/language-server@3.3.14, whose dependency
-- @vue/language-core@3.3.14 is missing from some npm caches and corporate
-- mirrors (npm ETARGET). 3.3.13 depends on language-core@3.3.13.
return {
  name = "vue-language-server",
  description = "Vue language server.",
  homepage = "https://github.com/vuejs/language-tools",
  licenses = { "MIT" },
  languages = { "Vue" },
  categories = { "LSP" },
  source = {
    id = "pkg:npm/%40vue/language-server@3.3.13",
    extra_packages = {
      "typescript@6.0.3",
      "@vue/typescript-plugin@3.3.13",
    },
  },
  bin = {
    ["vue-language-server"] = "npm:vue-language-server",
  },
  neovim = {
    lspconfig = "vue_ls",
  },
}
