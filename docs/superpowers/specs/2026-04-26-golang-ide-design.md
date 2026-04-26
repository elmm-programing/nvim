# Neovim Go IDE — Design Spec

**Date:** 2026-04-26
**Author:** Edwin Levinson Mejia Marcelino
**Status:** Approved (auto mode, brainstorming)

## Goal

Turn the existing Neovim configuration at `~/.config/nvim` into a full-featured Go IDE on par with VS Code + Go extension or GoLand for day-to-day work: code intelligence, debugging, test running, refactoring, code generation, linting, formatting, build/run, and coverage.

## Non-goals

- Replacing existing Java/Rust/Vue/TypeScript language support (additive only).
- Building generic project scaffolding tooling (out of scope).
- Adding a new colorscheme or UI redesign.
- Replacing already-working pieces (gopls, conform, dap-go, mason tools, blink.cmp, telescope) — those stay.

## Current state (already in repo)

| Area | Status |
|---|---|
| LSP — `gopls`, `golangci_lint_ls`, `templ` | Configured in `lua/plugins/lang/golang.lua` |
| Formatters — `goimports` → `golines` → `gofumpt` | Configured via conform |
| Treesitter — `go`, `gomod`, `gowork`, `gosum`, `templ` | Installed |
| Mason tools (delve, gomodifytags, gotests, iferr, impl, gci, goimports-reviser, nilaway, revive, golangci-lint, staticcheck, gotestsum, …) | Installed via `mason-tool-installer` |
| `nvim-dap` + `nvim-dap-go` (Delve) | Configured in `lua/plugins/dap.lua` |
| `neotest` | Installed but only `neotest-rust` adapter is registered |
| `lua/plugins/debug.lua` | **Disabled duplicate** of `dap.lua` — dead code |

## Gaps

1. Neotest has no Go adapter — `<leader>tt` does not run Go tests.
2. No `ray-x/go.nvim` — no one-shot commands for `iferr`, `fillstruct`, `addtags`/`rmtags`, generate tests, impl.
3. No Go-specific ftplugin — Go convention is hard tabs, width 4.
4. `gopls` is under-tuned — no inlay hints, codelenses, semantic tokens, vulncheck, postfix completions.
5. No explicit `*.templ` filetype detection.
6. No build/run/coverage keymaps.
7. `lua/plugins/debug.lua` is a confusing disabled duplicate.

## Architecture

The configuration follows a kickstart-style layout where each plugin lives in its own file under `lua/plugins/`, and language-specific extensions live under `lua/plugins/lang/<lang>.lua`. Files there return Lazy plugin specs that **extend** existing plugin opts via the `opts = function(_, opts) ... end` pattern (additive — no overwrites).

The Go IDE work follows this same convention:

```
lua/plugins/
├── neotest.lua             ← extend: register neotest-golang adapter
├── lang/
│   └── golang.lua          ← extend: gopls settings, add go.nvim, mason tools, conform
ftplugin/
└── go.lua                  ← new: tabs, width 4, no expandtab, colorcolumn
lua/config/
└── autocmds.lua            ← extend: filetype.add for *.templ
```

`lua/plugins/debug.lua` is deleted (dead disabled code).

## Components

### 1. `gopls` settings tightening

In `lua/plugins/lang/golang.lua`, expand the `gopls` settings block with:

- `hints` — parameterNames, assignVariableTypes, constantValues, rangeVariableTypes, compositeLiteralFields, compositeLiteralTypes, functionTypeParameters (all `true`)
- `codelenses` — generate, regenerate_cgo, run_govulncheck, test, tidy, upgrade_dependency, vendor (all `true`)
- `semanticTokens = true`
- `experimentalPostfixCompletions = true`
- `vulncheck = "Imports"`
- `analyses` — extend with `nilness = true`, `shadow = true`, `any = true`, `unusedwrite = true` (in addition to existing `unusedparams`)
- `directoryFilters = { "-.git", "-.vscode", "-.idea", "-node_modules" }` (avoid scanning generated dirs)
- `usePlaceholders = true` (already set)

Inlay hints are toggled per-buffer via the existing `<leader>th` keymap in `lsp.lua` — no extra wiring needed.

### 2. Neotest Go adapter

In `lua/plugins/neotest.lua`:

- Add `fredrikaverpil/neotest-golang` to `dependencies`.
- Append `require('neotest-golang')({ dap_go_enabled = true })` to the `adapters` list. This routes `<leader>td` (debug nearest test) through `dap-go`/Delve, which is already configured.

### 3. `ray-x/go.nvim`

New plugin block in `lua/plugins/lang/golang.lua`:

```lua
{
  'ray-x/go.nvim',
  dependencies = {
    'ray-x/guihua.lua',
    'neovim/nvim-lspconfig',
    'nvim-treesitter/nvim-treesitter',
  },
  ft = { 'go', 'gomod', 'gosum', 'gotmpl', 'gowork' },
  build = ':lua require("go.install").update_all_sync()',
  opts = {
    lsp_cfg = false,                       -- our gopls config wins
    lsp_inlay_hints = { enable = false },  -- handled by Neovim's built-in
    dap_debug = false,                     -- nvim-dap-go already handles this
    luasnip = false,
    trouble = true,
    test_runner = 'go',                    -- gotestsum is also available
    run_in_floaterm = true,
  },
}
```

`lsp_cfg = false` is critical — without it, `go.nvim` will spawn its own gopls and conflict with the existing one.

### 4. Go-specific keymaps

Add to the `go.nvim` block (or as a separate `lua/plugins/lang/golang.lua` keymap section), keys active only on Go buffers via `ft` lazy-loading:

| Keymap | Command | Description |
|---|---|---|
| `<leader>cgi` | `:GoIfErr` | Generate `if err != nil` boilerplate |
| `<leader>cgs` | `:GoFillStruct` | Fill struct with zero values |
| `<leader>cgc` | `:GoFillSwitch` | Fill switch arms |
| `<leader>cgt` | `:GoAddTag` | Add struct tags (json, yaml, …) |
| `<leader>cgT` | `:GoRmTag` | Remove struct tags |
| `<leader>cgI` | `:GoImpl` | Generate interface stubs |
| `<leader>cga` | `:GoTestAdd` | Generate test for current func |
| `<leader>cgA` | `:GoTestsAll` | Generate tests for whole file |
| `<leader>cgm` | `:GoMod tidy` | Run `go mod tidy` |
| `<leader>cgr` | `:GoRun` | Run current package |
| `<leader>cgb` | `:GoBuild` | Build current package |
| `<leader>cgv` | `:GoCoverage -t` | Toggle coverage gutter |
| `<leader>cgg` | `:GoGenerate` | Run `go generate` |

Group label `cg` = "**c**ode → **g**o". Sits next to the existing `<leader>c*` LSP code group, so the muscle memory is consistent.

Register the group label with `which-key` if present, otherwise plain `vim.keymap.set` with descriptions.

### 5. Go ftplugin

New file `ftplugin/go.lua`:

```lua
vim.bo.expandtab = false
vim.bo.tabstop = 4
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4
vim.opt_local.colorcolumn = '120'
vim.opt_local.list = false  -- avoid showing tabs as visible chars
```

This is sourced by Neovim automatically on Go buffers.

### 6. Templ filetype

Add to `lua/config/autocmds.lua`:

```lua
vim.filetype.add({ extension = { templ = 'templ' } })
```

Treesitter parser and templ LSP are already configured in `lua/plugins/lang/golang.lua`.

### 7. Delete dead code

Remove `lua/plugins/debug.lua` entirely. It is a disabled (`enabled = false`) duplicate of `lua/plugins/dap.lua` and adds confusion.

## Data flow

1. User opens `*.go` → ftplugin runs → tabs/width set.
2. Lazy.nvim loads `go.nvim` (ft trigger) → `:Go*` commands available.
3. `gopls` (auto-attached via lspconfig) provides hover/definition/references/codelens/inlay hints.
4. `golangci_lint_ls` runs in parallel and surfaces lint diagnostics.
5. On save: conform runs `goimports` → `golines` → `gofumpt`.
6. Test running: `<leader>tt` → neotest → `neotest-golang` → `go test` (or `gotestsum`).
7. Test debugging: `<leader>td` → neotest with DAP strategy → `dap-go` → Delve.
8. Manual debugging: `<leader>dc` (continue), `<leader>db` (toggle breakpoint) — already wired in `dap.lua`.

## Error handling

- If `gopls` is missing, `mason-tool-installer` installs it on first run.
- If `go.nvim`'s `update_all_sync()` build step fails (e.g., no network), command failures are reported via Neovim's normal `:messages`. The user can re-run via `:Lazy build go.nvim`.
- `dap_go_enabled = true` for `neotest-golang` is a no-op when `dap-go` is missing — no crash.
- Templ filetype detection is a pure `vim.filetype.add` call — no failure mode.

## Testing

Manual verification (no automated tests for an Nvim config):

1. Open a `.go` file in a Go project — confirm `gopls` attaches (`:LspInfo`).
2. Hover (`K`) shows docs; `gd` jumps to definition; inlay hints toggle via `<leader>th`.
3. `:GoFillStruct` fills a struct literal; `:GoIfErr` inserts boilerplate; `:GoAddTag` adds `json:"…"`.
4. `<leader>tt` runs the nearest test via `neotest`.
5. `<leader>td` debugs the nearest test (Delve breakpoints hit).
6. `<leader>dc` starts a debug session for `main`; `<leader>db` toggles breakpoints.
7. Save a Go file — `goimports`/`golines`/`gofumpt` run automatically.
8. Open a `.templ` file — confirm `templ` filetype, treesitter highlights, templ LSP attaches.
9. `<leader>cgr` runs `go run`; `<leader>cgb` builds.
10. `<leader>cgv` toggles coverage gutter on a tested package.

## Risk and rollback

- **Risk:** `go.nvim` may conflict with existing `gopls` if `lsp_cfg = false` is forgotten → mitigation explicit in spec.
- **Risk:** `neotest-golang` requires `go test` to be in `$PATH` — already true on macOS dev box.
- **Risk:** `gopls` `directoryFilters` may hide useful files in unusual repo layouts — easy to revert.
- **Rollback:** `git revert` the implementation commit; lazy-lock will pin restored versions.

## Out of scope (YAGNI)

- `golangci-lint` via `nvim-lint` — `golangci_lint_ls` covers it via LSP.
- A dedicated DAP config block — `dap-go` auto-configures Delve.
- Go-specific snippets — gopls + postfix completions are enough.
- Overseer task templates — `:GoRun`/`:GoBuild` already cover the run/build loop.
- Renaming the keymap prefix — `<leader>cg` reuses the existing `<leader>c*` code group.
