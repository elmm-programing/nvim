-- Headless Mason install. Run after plugins are synced:
--   nvim --headless "+luafile install/mason-sync.lua"
local packages = {
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
  "js-debug-adapter",
  "java-debug-adapter",
  "java-test",
  "delve",
  "gofumpt",
  "goimports",
  "golangci-lint",
  "prettier",
  "stylua",
  "google-java-format",
  "vue-language-server",
  "eslint_d",
  "rust-analyzer",
  "codelldb",
}

local function fail(message)
  io.stderr:write(message .. "\n")
  vim.cmd("cquit")
end

local lazy_ok, lazy = pcall(require, "lazy")
if not lazy_ok then
  fail("lazy.nvim is not loaded. Run :Lazy sync in nvim.")
end
pcall(function()
  lazy.load({ plugins = { "mason.nvim" } })
end)
local mason_ok = pcall(require, "mason")
if not mason_ok then
  fail("mason.nvim is not installed. Run :Lazy sync in nvim.")
end

local registry = require("mason-registry")
local refreshed = false
registry.refresh(function()
  refreshed = true
end)
if not vim.wait(120000, function()
  return refreshed
end, 200) then
  fail("Timed out refreshing the Mason registry.")
end

for _, name in ipairs(packages) do
  local ok, pkg = pcall(registry.get_package, name)
  if ok and not pkg:is_installed() then
    pkg:install()
  end
end

local function missing()
  local left = {}
  for _, name in ipairs(packages) do
    local ok, pkg = pcall(registry.get_package, name)
    if not ok or not pkg:is_installed() then
      table.insert(left, name)
    end
  end
  return left
end

vim.wait(15 * 60 * 1000, function()
  return #missing() == 0
end, 2000)

local left = missing()
if #left == 0 then
  print("Mason packages installed")
  vim.cmd("qa!")
else
  fail("Still missing after 15 minutes: " .. table.concat(left, ", "))
end
