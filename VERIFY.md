# Neovim config verification checklist

After pull / restart: `:Lazy sync` then work through this list.

## 0. Health

- [ ] `:checkhealth` — no critical errors
- [ ] `:checkhealth mason`
- [ ] `:checkhealth lsp`
- [ ] `:Mason` — tools from `mason-tool-installer`: gofumpt, goimports, delve, golangci-lint, prettier, eslint_d, stylua, google-java-format, java-debug-adapter, java-test, js-debug-adapter, vue-language-server, rust-analyzer, codelldb
- [ ] `:Mason` — language servers from `mason-lspconfig`: gopls, ts_ls, jdtls, lua_ls, yamlls, jsonls, dockerls, bashls, tailwindcss, html, cssls, emmet_ls

## 1. LSP ownership (no overlaps)

| Filetype | Expected clients (`:LspInfo`) |
|----------|-------------------------------|
| `.ts` / `.tsx` / `.js` | `ts_ls` only |
| `.vue` | `volar` only (`hybridMode` is off) |
| `.go` | `gopls` (`go`, `gomod`, `gowork`) |
| `.java` | `jdtls` once (nvim-jdtls only) |
| `.lua` | `lua_ls` |
| `.json` / `.jsonc` | `jsonls` (SchemaStore limited to package.json, tsconfig, eslintrc, prettierrc, jsconfig) |
| `.yaml` / `.yml` | `yamlls` (SchemaStore limited to GitHub Workflow, GitHub Action, docker-compose) |

`vue-language-server` is installed by Mason. The client name is `volar`, not `vue_ls` or `vtsls`.

## 2. Format on save (conform)

- [ ] TS/JS/Vue → prettier
- [ ] Go → goimports + gofumpt
- [ ] Java → google-java-format
- [ ] Lua → stylua
- [ ] Rust → rustfmt
- [ ] `:ConformInfo` shows formatters available

## 3. Debug

- [ ] Go: breakpoint `<leader>Db`, continue `<leader>Dc` (delve via dap-go)
- [ ] Java: open a class with `main`, `<leader>Db`, `<leader>Dc` (needs java-debug-adapter)
- [ ] Java test debug: `<leader>jt` / `<leader>jn`
- [ ] DAP UI toggles with `<leader>Du`

## 4. Tests (neotest owns `<leader>t*`)

- [ ] `<leader>tt` nearest · `<leader>tf` file · `<leader>tS` summary
- [ ] `<leader>td` debug nearest
- [ ] Coverage: `<leader>tc` / `<leader>tC`

## 5. Keymap groups (which-key)

Press `<leader>` and confirm groups:

| Prefix | Group |
|--------|--------|
| `f` | file/find |
| `g` | git |
| `G` | go |
| `b` | buffer |
| `t` | test |
| `j` | java |
| `D` | debug |
| `c` | code/lsp |
| `u` | ui |
| `h` | git hunks |
| `x` | diagnostics |
| `w` | workspace/save |
| `s` | search/symbols |
| `r` | refactor |
| `q` | quit/session |
| `R` | rust |
| `<tab>` | tabs |

Spot-checks:

- [ ] `<C-h/j/k/l>` move windows (signature help stays on `gK` / insert `<C-s>`)
- [ ] `<leader>uh` toggles inlay hints (on by default for gopls, ts_ls, volar, jdtls, rust_analyzer)
- [ ] `<leader>\` floating terminal
- [ ] `<leader>y` yank history
- [ ] `<leader>a` harpoon add
- [ ] `>p` / `<p` swap parameters (treesitter)
- [ ] `<leader>gc` Neogit commit · `<leader>gL` Telescope git log
- [ ] `<leader>qs` restore session · `<leader>ql` last session · `<leader>qS` save session · `<leader>qd` stop saving
- [ ] `gr` finds references immediately (default `grn` / `gra` / `grr` / `gri` / `grt` / `grx` are removed)
- [ ] Treesitter incremental selection: `gnn` start, `gni` expand, `gnd` shrink, `gns` scope

## 6. Performance

- [ ] Current-line blame is on; `<leader>hb` shows the full blame
- [ ] Open a file >1MB → snacks bigfile handling; no LSP/TS thrash

## 7. Treesitter (if highlight / `K` hover crashes)

Unnamed markdown floats skip Treesitter highlight, and an autocmd disables Treesitter in LSP hover markdown. That covers the `conceal_line` / `node:range` crash from nvim-treesitter `master` on Neovim 0.12+.

```bash
brew install tree-sitter   # or cargo install tree-sitter-cli
# inside nvim:
:TSUpdate
```

## 8. Profile tips

- Java workspaces cache under `stdpath("cache")/jdtls/workspace/<project>`
- First Mason install can take several minutes — wait before judging LSP
- `:Lazy profile` after a cold start if startup feels slow
- `~/go/bin` is prepended to `PATH` when that directory exists, so go.nvim health can see GOPATH tools

## Quick smoke (2 minutes)

```text
1. nvim somefile.ts   → :LspInfo → ts_ls
2. nvim App.vue       → :LspInfo → volar
3. nvim main.go       → save → formatted; <leader>Gr run
4. nvim Main.java     → :LspInfo → jdtls; <leader>ji organize
5. <leader>tt         → neotest runs
6. <leader>?          → which-key full map
```
