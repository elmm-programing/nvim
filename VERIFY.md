# Neovim config verification checklist (Mac branch)

After pull / restart: `:Lazy sync` then work through this list.

## 0. Health

- [ ] `:checkhealth` — no critical errors
- [ ] `:checkhealth mason`
- [ ] `:checkhealth lsp`
- [ ] `:Mason` — tools present: gofumpt, goimports, delve, prettier, eslint_d, stylua, google-java-format, java-debug-adapter, java-test, jdtls, vue-language-server, vtsls

## 1. LSP ownership (no overlaps)

| Filetype | Expected clients (`:LspInfo`) |
|----------|-------------------------------|
| `.ts` / `.tsx` / `.js` | `vtsls` only (no `ts_ls`) |
| `.vue` | `vue_ls` + `vtsls` (hybrid; `@vue/typescript-plugin`) |
| `.go` | `gopls` |
| `.java` | `jdtls` once (nvim-jdtls only) |
| `.lua` | `lua_ls` |

Optional Vue hybrid: `npm i -D typescript @vue/typescript-plugin`

## 2. Format on save (conform)

- [ ] TS/JS/Vue → prettier
- [ ] Go → gofumpt + goimports (+ organize imports autocmd)
- [ ] Java → google-java-format
- [ ] Lua → stylua
- [ ] `:ConformInfo` shows formatters available

## 3. Debug

- [ ] Go: breakpoint `<leader>Db`, continue `<leader>Dc` (delve via dap-go)
- [ ] Java: open class with `main`, `<leader>Db`, `<leader>Dc` (needs java-debug-adapter)
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
| `t` | test |
| `T` | typescript |
| `j` | java |
| `v` | vue |
| `D` | debug |
| `c` | code/lsp |
| `o` | open/terminal |
| `u` | ui |
| `h` | git hunks |
| `x` | diagnostics |

Spot-checks:

- [ ] `<C-h/j/k/l>` move windows (not stolen by signature help)
- [ ] `<leader>uh` toggles inlay hints
- [ ] `<leader>ot` / `<leader>\` floating terminal
- [ ] `<leader>yh` yank history (clipboard stays `<leader>y`)
- [ ] `<leader>a` harpoon add (not parameter swap)
- [ ] `>p` / `<p` swap parameters (treesitter)
- [ ] `<leader>gC` Neogit commit · `<leader>gc` Telescope commits

## 6. Performance

- [ ] No always-on current line blame (`<leader>hB` to toggle)
- [ ] Inlay hints off until `<leader>uh`
- [ ] Open a file >1MB → huge-file notice; no LSP/TS thrash
- [ ] Open a file ~600KB → large-file notice; gitsigns/ibl off

## 7. Treesitter (if highlight / `K` hover crashes)

`conceal_line` / `node:range` nil on hover is nvim-treesitter **master** vs Neovim **0.12+**
(query match shape). Config applies `treesitter-workaround.patch_query_handlers` after load.

```bash
brew install tree-sitter   # or cargo install tree-sitter-cli
# inside nvim:
:TSUpdate
# last resort:
bash ~/.config/nvim/fix-treesitter.sh
```

Long-term: migrate nvim-treesitter (+ textobjects) to branch **main** (Nvim 0.12+ rewrite).

## 8. Profile tips

- Prefer project-local `node_modules/typescript` for Vue/TS monorepos
- Java workspaces cache under `stdpath("cache")/jdtls/workspace/<project>`
- First Mason install can take several minutes — wait before judging LSP
- `:Lazy profile` after a cold start if startup feels slow

## Quick smoke (2 minutes)

```text
1. nvim somefile.ts   → :LspInfo → vtsls
2. nvim App.vue       → :LspInfo → vue_ls + vtsls
3. nvim main.go       → save → formatted; <leader>Gt test
4. nvim Main.java     → :LspInfo → jdtls; <leader>ji organize
5. <leader>tt         → neotest runs
6. <leader>?          → which-key full map
```
