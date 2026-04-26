# Neovim Go IDE Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the existing Neovim config at `~/.config/nvim` into a full Go IDE: tuned gopls, neotest-golang adapter, ray-x/go.nvim with code-gen keymaps, Go ftplugin, templ filetype detection, and removal of dead disabled DAP file.

**Architecture:** Additive changes to existing kickstart-style config. Each plugin extends opts via the `opts = function(_, opts) ... end` pattern (no overwrites). Language work concentrates in `lua/plugins/lang/golang.lua`; ftplugin lives in `ftplugin/go.lua`; filetype registration goes into `lua/config/autocmds.lua`.

**Tech Stack:** Lua, Neovim ≥ 0.11, lazy.nvim, gopls, ray-x/go.nvim, fredrikaverpil/neotest-golang, leoluz/nvim-dap-go (already installed), conform.nvim, mason.nvim.

**Note on testing:** This is a Neovim configuration repo, not application code. There is no unit-test harness. Verification is done by:
1. **`nvim --headless` syntax check** — confirms the file parses and lazy spec loads.
2. **Interactive smoke test** — open a real Go file and exercise the affected feature.

Each task includes both. "Run test, expect FAIL" is replaced with "Run syntax check, expect SUCCESS" because there is no production code to fail against. Where a task changes runtime behavior, an interactive smoke test is included.

---

## File Structure

| Path | Action | Responsibility |
|---|---|---|
| `lua/plugins/lang/golang.lua` | Modify | gopls settings, conform formatters, treesitter parsers, mason tools, **add** `go.nvim` plugin block + Go-only keymaps |
| `lua/plugins/neotest.lua` | Modify | Register `neotest-golang` adapter alongside existing `neotest-rust` |
| `ftplugin/go.lua` | Create | Go-buffer-local options: hard tabs, width 4, colorcolumn 120 |
| `lua/config/autocmds.lua` | Modify | Add `vim.filetype.add` for `*.templ` |
| `lua/plugins/debug.lua` | Delete | Disabled duplicate of `lua/plugins/dap.lua` |
| `docs/superpowers/specs/2026-04-26-golang-ide-design.md` | (already committed) | Source spec |

---

## Task 1: Verify baseline — config loads cleanly before changes

**Files:**
- Read-only: full repo

- [ ] **Step 1: Confirm headless boot succeeds**

Run:
```bash
cd /Users/elmm12/.config/nvim && nvim --headless "+Lazy! sync" "+qa" 2>&1 | tail -20
```

Expected: No Lua errors. Plugin sync output may scroll; the final lines should be benign (e.g. `[Lazy]`/no error stack traces). If errors appear, stop and report — do not proceed until baseline is clean.

- [ ] **Step 2: Confirm a known plugin file parses**

Run:
```bash
cd /Users/elmm12/.config/nvim && nvim --headless -c 'luafile lua/plugins/lang/golang.lua' -c 'qa' 2>&1
```

Expected: No output (silent success). Any error means the file is already broken — fix before continuing.

- [ ] **Step 3: Capture current gopls settings for diff comparison later**

Run:
```bash
cd /Users/elmm12/.config/nvim && cp lua/plugins/lang/golang.lua /tmp/golang.lua.before
```

Expected: file copied. (Used in Task 11 self-review.)

No commit yet — this task only verifies baseline.

---

## Task 2: Tighten gopls settings

**Files:**
- Modify: `lua/plugins/lang/golang.lua` (lines 43-55, the `opts.servers.gopls = { ... }` block)

- [ ] **Step 1: Open file and replace the gopls block**

Replace lines 43-55:
```lua
      opts.servers.gopls = {
        settings = {
          gopls = {
            gofumpt = true,
            usePlaceholders = true,
            analyses = {
              unusedparams = true,
            },
            -- Tell gopls to use the statically installed staticcheck
            staticcheck = true,
          },
        },
      }
```

with:
```lua
      opts.servers.gopls = {
        settings = {
          gopls = {
            gofumpt = true,
            usePlaceholders = true,
            staticcheck = true,
            semanticTokens = true,
            experimentalPostfixCompletions = true,
            vulncheck = 'Imports',
            directoryFilters = { '-.git', '-.vscode', '-.idea', '-node_modules' },
            analyses = {
              unusedparams = true,
              unusedwrite = true,
              nilness = true,
              shadow = true,
              any = true,
            },
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              compositeLiteralTypes = true,
              constantValues = true,
              functionTypeParameters = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
            codelenses = {
              generate = true,
              regenerate_cgo = true,
              run_govulncheck = true,
              test = true,
              tidy = true,
              upgrade_dependency = true,
              vendor = true,
            },
          },
        },
      }
```

- [ ] **Step 2: Verify file parses**

Run:
```bash
cd /Users/elmm12/.config/nvim && nvim --headless -c 'luafile lua/plugins/lang/golang.lua' -c 'qa' 2>&1
```

Expected: silent success.

- [ ] **Step 3: Verify lazy.nvim accepts the spec**

Run:
```bash
cd /Users/elmm12/.config/nvim && nvim --headless "+checkhealth lazy" "+qa" 2>&1 | grep -i error
```

Expected: no output (no errors from lazy).

- [ ] **Step 4: Smoke test in Neovim (manual)**

Open a real Go file (any `.go` file in any Go module on disk, e.g. clone `https://github.com/golang/example` if needed):
```bash
nvim /path/to/some.go
```

In Neovim:
1. `:LspInfo` — confirm `gopls` is attached and reports no startup error.
2. `:lua =vim.lsp.get_clients({ name = 'gopls' })[1].config.settings.gopls.hints.parameterNames` — expected: `true`.
3. Press `<leader>th` to toggle inlay hints; confirm hint chips appear next to function calls.

If any step fails: revert the block and inspect with `:LspLog`.

- [ ] **Step 5: Commit**

```bash
cd /Users/elmm12/.config/nvim && git add lua/plugins/lang/golang.lua && git commit -m "$(cat <<'EOF'
feat(go): tighten gopls settings for IDE parity

Adds inlay hints, codelenses, vulncheck, semantic tokens, postfix
completions, additional analyses (nilness, shadow, any, unusedwrite),
and directory filters.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Register neotest-golang adapter

**Files:**
- Modify: `lua/plugins/neotest.lua`

- [ ] **Step 1: Add neotest-golang to dependencies**

In `lua/plugins/neotest.lua`, change lines 3-9:
```lua
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'antoinemadec/FixCursorHold.nvim',
    'nvim-treesitter/nvim-treesitter',
    'rouge8/neotest-rust',
  },
```

to:
```lua
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'antoinemadec/FixCursorHold.nvim',
    'nvim-treesitter/nvim-treesitter',
    'rouge8/neotest-rust',
    'fredrikaverpil/neotest-golang',
  },
```

- [ ] **Step 2: Register the Go adapter alongside Rust**

In the same file, change lines 22-29:
```lua
    require('neotest').setup({
      adapters = {
        require('neotest-rust')({
          args = { '--no-capture' },
        }),
      },
```

to:
```lua
    require('neotest').setup({
      adapters = {
        require('neotest-rust')({
          args = { '--no-capture' },
        }),
        require('neotest-golang')({
          dap_go_enabled = true,
        }),
      },
```

- [ ] **Step 3: Verify file parses**

Run:
```bash
cd /Users/elmm12/.config/nvim && nvim --headless -c 'luafile lua/plugins/neotest.lua' -c 'qa' 2>&1
```

Expected: silent success.

- [ ] **Step 4: Install the new plugin**

Run:
```bash
cd /Users/elmm12/.config/nvim && nvim --headless "+Lazy! sync" "+qa" 2>&1 | tail -5
```

Expected: lazy reports `neotest-golang` cloned. No error stack traces.

- [ ] **Step 5: Smoke test in Neovim (manual)**

In a Go project with at least one `_test.go` file:
```bash
nvim /path/to/some_test.go
```

1. Position cursor inside a `Test*` function.
2. Press `<leader>tt` — neotest should run that test and show pass/fail virtual text.
3. Press `<leader>ts` — summary panel opens listing tests.
4. Press `<leader>td` on a test — DAP session starts via `dap-go` (Delve), break at first line if a breakpoint set.

If `<leader>tt` reports "no adapter for filetype go", re-check Step 2.

- [ ] **Step 6: Commit**

```bash
cd /Users/elmm12/.config/nvim && git add lua/plugins/neotest.lua && git commit -m "$(cat <<'EOF'
feat(go): register neotest-golang adapter with DAP support

Wires fredrikaverpil/neotest-golang into the neotest setup with
dap_go_enabled so <leader>td routes through Delve via nvim-dap-go.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Add ray-x/go.nvim plugin block

**Files:**
- Modify: `lua/plugins/lang/golang.lua` (append a new plugin block before the closing `}`)

- [ ] **Step 1: Append the go.nvim block**

In `lua/plugins/lang/golang.lua`, find the last plugin block (the treesitter block ending around line 84) and after its closing `},` and before the file's final `}`, insert:

```lua
  -- Go IDE features: code generation, build/run, coverage
  {
    'ray-x/go.nvim',
    dependencies = {
      'ray-x/guihua.lua',
      'neovim/nvim-lspconfig',
      'nvim-treesitter/nvim-treesitter',
      'folke/trouble.nvim',
      'voldikss/vim-floaterm',
    },
    ft = { 'go', 'gomod', 'gosum', 'gotmpl', 'gowork' },
    build = ':lua require("go.install").update_all_sync()',
    opts = {
      lsp_cfg = false,
      lsp_inlay_hints = { enable = false },
      dap_debug = false,
      luasnip = false,
      trouble = true,
      test_runner = 'go',
      run_in_floaterm = true,
    },
    config = function(_, opts)
      require('go').setup(opts)
    end,
  },
```

The result: file ends with `},\n}\n` where the new block is the last entry in the returned list.

- [ ] **Step 2: Verify file parses**

Run:
```bash
cd /Users/elmm12/.config/nvim && nvim --headless -c 'luafile lua/plugins/lang/golang.lua' -c 'qa' 2>&1
```

Expected: silent success.

- [ ] **Step 3: Install the plugin**

Run:
```bash
cd /Users/elmm12/.config/nvim && nvim --headless "+Lazy! sync" "+qa" 2>&1 | tail -5
```

Expected: `go.nvim` and `guihua.lua` cloned.

- [ ] **Step 4: Run go.nvim's installer for downstream tools**

Run:
```bash
cd /Users/elmm12/.config/nvim && nvim --headless "+lua require('go.install').update_all_sync()" "+qa" 2>&1 | tail -10
```

Expected: lines like `gomodifytags installed` etc. (no error). Mason already has most; this is idempotent.

- [ ] **Step 5: Smoke test in Neovim (manual)**

Open a Go file:
```bash
nvim /path/to/some.go
```

In Neovim:
1. `:Go` then press `<Tab>` — completion should list `:GoBuild`, `:GoRun`, `:GoTest`, `:GoFillStruct`, `:GoIfErr`, etc.
2. `:GoBuild` — should run `go build` against the current package and show output.
3. `:LspInfo` — confirm only **one** `gopls` client (go.nvim must NOT spawn its own; `lsp_cfg = false` prevents this).

If two `gopls` clients are listed, `lsp_cfg = false` was forgotten — fix Step 1.

- [ ] **Step 6: Commit**

```bash
cd /Users/elmm12/.config/nvim && git add lua/plugins/lang/golang.lua && git commit -m "$(cat <<'EOF'
feat(go): add ray-x/go.nvim for IDE code-gen and build/run

Provides :Go* commands for fillstruct, iferr, addtag/rmtag, impl,
testadd, run, build, coverage, generate. lsp_cfg=false avoids
clobbering the existing gopls config.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Add Go-only keymaps via go.nvim's `keys` table

**Files:**
- Modify: `lua/plugins/lang/golang.lua` (the `go.nvim` block from Task 4)

- [ ] **Step 1: Add a `keys` table to the go.nvim block**

In the `go.nvim` block, between `ft = { ... },` and `build = ...,`, insert:

```lua
    keys = {
      { '<leader>cgi', '<cmd>GoIfErr<cr>',         desc = 'Go: if err', ft = 'go' },
      { '<leader>cgs', '<cmd>GoFillStruct<cr>',    desc = 'Go: fill struct', ft = 'go' },
      { '<leader>cgc', '<cmd>GoFillSwitch<cr>',    desc = 'Go: fill switch', ft = 'go' },
      { '<leader>cgt', '<cmd>GoAddTag<cr>',        desc = 'Go: add tag', ft = 'go' },
      { '<leader>cgT', '<cmd>GoRmTag<cr>',         desc = 'Go: remove tag', ft = 'go' },
      { '<leader>cgI', '<cmd>GoImpl<cr>',          desc = 'Go: impl interface', ft = 'go' },
      { '<leader>cga', '<cmd>GoTestAdd<cr>',       desc = 'Go: gen test (func)', ft = 'go' },
      { '<leader>cgA', '<cmd>GoTestsAll<cr>',      desc = 'Go: gen tests (file)', ft = 'go' },
      { '<leader>cgm', '<cmd>GoMod tidy<cr>',      desc = 'Go: mod tidy', ft = 'go' },
      { '<leader>cgr', '<cmd>GoRun<cr>',           desc = 'Go: run', ft = 'go' },
      { '<leader>cgb', '<cmd>GoBuild<cr>',         desc = 'Go: build', ft = 'go' },
      { '<leader>cgv', '<cmd>GoCoverage -t<cr>',   desc = 'Go: toggle coverage', ft = 'go' },
      { '<leader>cgg', '<cmd>GoGenerate<cr>',      desc = 'Go: generate', ft = 'go' },
    },
```

The `ft = 'go'` field tells lazy.nvim these keys only register in Go buffers (and additionally lazy-trigger `go.nvim` to load if not already loaded).

- [ ] **Step 2: Verify file parses**

Run:
```bash
cd /Users/elmm12/.config/nvim && nvim --headless -c 'luafile lua/plugins/lang/golang.lua' -c 'qa' 2>&1
```

Expected: silent success.

- [ ] **Step 3: Verify lazy keymap registration**

Run:
```bash
cd /Users/elmm12/.config/nvim && nvim --headless "+Lazy! sync" "+qa" 2>&1 | tail -5
```

Expected: no errors.

- [ ] **Step 4: Smoke test in Neovim (manual)**

Open a Go file with a struct definition:
```bash
nvim /path/to/some.go
```

In Neovim:
1. Position cursor on a struct field, press `<leader>cgt`, type `json` at the prompt — confirm `json:"..."` tag is added.
2. Position cursor on `var x SomeStruct` and press `<leader>cgs` — confirm struct literal is filled with zero values.
3. Inside a function returning `(T, error)`, after a call returning `error`, press `<leader>cgi` — confirm `if err != nil { return ... }` boilerplate appears.
4. `:WhichKey <leader>cg` (if which-key is loaded) — confirm group label shows all 13 entries.

- [ ] **Step 5: Commit**

```bash
cd /Users/elmm12/.config/nvim && git add lua/plugins/lang/golang.lua && git commit -m "$(cat <<'EOF'
feat(go): add Go-only <leader>cg* keymaps for go.nvim commands

13 buffer-local keymaps covering iferr, fillstruct, fillswitch,
addtag/rmtag, impl, testadd, mod tidy, run, build, coverage,
generate. ft='go' restricts to Go buffers via lazy.nvim.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Create Go ftplugin

**Files:**
- Create: `ftplugin/go.lua`

- [ ] **Step 1: Create the ftplugin file**

Create `ftplugin/go.lua` with exactly this content:
```lua
-- Buffer-local options for Go files: hard tabs, width 4, colorcolumn 120.
-- Sourced automatically by Neovim on filetype=go buffers.

vim.bo.expandtab = false
vim.bo.tabstop = 4
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4
vim.opt_local.colorcolumn = '120'
vim.opt_local.list = false
```

- [ ] **Step 2: Verify file parses**

Run:
```bash
cd /Users/elmm12/.config/nvim && nvim --headless -c 'luafile ftplugin/go.lua' -c 'qa' 2>&1
```

Expected: silent success.

- [ ] **Step 3: Smoke test in Neovim (manual)**

Open a Go file:
```bash
nvim /path/to/some.go
```

In Neovim:
1. `:set tabstop?` — expected: `tabstop=4`.
2. `:set expandtab?` — expected: `noexpandtab`.
3. `:set colorcolumn?` — expected: `colorcolumn=120`.

Then open a non-Go file (`.lua`, `.md`) — confirm those settings are NOT applied (buffer-local only).

- [ ] **Step 4: Commit**

```bash
cd /Users/elmm12/.config/nvim && git add ftplugin/go.lua && git commit -m "$(cat <<'EOF'
feat(go): add ftplugin/go.lua with hard tabs and colorcolumn

Go convention: hard tabs width 4, colorcolumn at 120. Buffer-local
so other filetypes are unaffected.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Register *.templ filetype

**Files:**
- Modify: `lua/config/autocmds.lua`

- [ ] **Step 1: Append filetype registration**

Append to `lua/config/autocmds.lua` (after the existing `TextYankPost` autocmd, end of file):

```lua

-- Register Go templ filetype so the templ LSP and treesitter parser attach.
vim.filetype.add({ extension = { templ = 'templ' } })
```

- [ ] **Step 2: Verify file parses**

Run:
```bash
cd /Users/elmm12/.config/nvim && nvim --headless -c 'luafile lua/config/autocmds.lua' -c 'qa' 2>&1
```

Expected: silent success.

- [ ] **Step 3: Smoke test in Neovim (manual)**

Create a throwaway `.templ` file:
```bash
mkdir -p /tmp/templ-test && cat > /tmp/templ-test/hello.templ <<'EOF'
package hello

templ Greeting(name string) {
  <div>Hello, { name }!</div>
}
EOF
nvim /tmp/templ-test/hello.templ
```

In Neovim:
1. `:set filetype?` — expected: `filetype=templ`.
2. `:LspInfo` — expected: `templ` LSP attached (after Mason installs it on first run).
3. Treesitter highlighting visible (HTML inside `templ ... { ... }`).

- [ ] **Step 4: Commit**

```bash
cd /Users/elmm12/.config/nvim && git add lua/config/autocmds.lua && git commit -m "$(cat <<'EOF'
feat(go): register *.templ filetype for templ LSP and treesitter

vim.filetype.add ensures .templ files are recognized so the existing
templ LSP and treesitter parser attach automatically.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Delete dead `lua/plugins/debug.lua`

**Files:**
- Delete: `lua/plugins/debug.lua`

- [ ] **Step 1: Confirm it's a disabled duplicate**

Run:
```bash
cd /Users/elmm12/.config/nvim && grep -n 'enabled = false' lua/plugins/debug.lua
```

Expected: `12:  enabled = false, -- Cleanly disables the plugin` (or similar). This confirms the file is inactive.

Also verify `dap.lua` already covers it:
```bash
cd /Users/elmm12/.config/nvim && grep -c "leoluz/nvim-dap-go" lua/plugins/dap.lua
```

Expected: `1` (DAP-go is wired up in the live `dap.lua`).

- [ ] **Step 2: Delete the file**

Run:
```bash
cd /Users/elmm12/.config/nvim && rm lua/plugins/debug.lua
```

- [ ] **Step 3: Verify config still loads**

Run:
```bash
cd /Users/elmm12/.config/nvim && nvim --headless "+Lazy! sync" "+qa" 2>&1 | tail -5
```

Expected: no errors. lazy may report `dap.lua` and `nvim-dap-go` (both still active).

- [ ] **Step 4: Smoke test in Neovim (manual)**

```bash
nvim /path/to/some.go
```

In Neovim:
1. `<leader>dc` — DAP starts (or prompts for config). Confirm `dap-go` provides Go configurations.
2. `<leader>db` — toggles a breakpoint.

If DAP keymaps no longer work, restore `debug.lua` and investigate; otherwise the deletion is safe.

- [ ] **Step 5: Commit**

```bash
cd /Users/elmm12/.config/nvim && git add -A && git commit -m "$(cat <<'EOF'
chore: remove dead lua/plugins/debug.lua

File was enabled=false and superseded by lua/plugins/dap.lua.
Removed to avoid confusion.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Final integration smoke test

**Files:**
- Read-only: full repo

- [ ] **Step 1: Full headless boot from scratch**

Run:
```bash
cd /Users/elmm12/.config/nvim && nvim --headless "+Lazy! sync" "+qa" 2>&1 | grep -iE 'error|fail' | head -20
```

Expected: no output (no errors, no failures).

- [ ] **Step 2: Health check**

Run:
```bash
cd /Users/elmm12/.config/nvim && nvim --headless "+checkhealth" "+w! /tmp/health.txt" "+qa" 2>&1 ; grep -iE 'ERROR' /tmp/health.txt | head -20
```

Expected: no `ERROR` lines from `lazy`, `mason`, `lspconfig`, `treesitter`, `dap`, `neotest`. Some warnings (e.g. missing optional providers) are fine.

- [ ] **Step 3: End-to-end manual checklist**

Open a real Go project:
```bash
nvim /path/to/go-project/main.go
```

Run through this checklist (all should succeed):

| # | Action | Expected |
|---|---|---|
| 1 | `:LspInfo` | `gopls` + `golangci_lint_ls` attached |
| 2 | Hover (`K`) over a type | Doc popup |
| 3 | `gd` on a symbol | Jump to definition |
| 4 | `<leader>th` | Inlay hints toggle visible |
| 5 | `<leader>cgs` on `var x Foo` | Struct fills with zero values |
| 6 | `<leader>cgi` after error-returning call | `if err != nil` boilerplate |
| 7 | `<leader>cgt` on struct field | Tag prompt → tag added |
| 8 | `:w` on a Go file | `goimports` + `golines` + `gofumpt` run |
| 9 | `<leader>tt` in `_test.go` on test func | Test runs, virtual-text result |
| 10 | `<leader>td` in `_test.go` | DAP session starts via Delve |
| 11 | `<leader>dc` in `main.go` | Debug session prompts/starts |
| 12 | `<leader>cgr` | `:GoRun` executes |
| 13 | `<leader>cgb` | `:GoBuild` executes |
| 14 | Open a `.templ` file | filetype=templ, templ LSP attaches |

If any item fails: identify the responsible task above, fix, retest. Do not proceed to Step 4 until all pass.

- [ ] **Step 4: No commit**

This task is verification only.

---

## Task 10: Update plan tracking

**Files:**
- Modify: `docs/superpowers/plans/2026-04-26-golang-ide.md` (this file)

- [ ] **Step 1: Mark all checkboxes complete**

Open this plan in editor and convert remaining `- [ ]` to `- [x]` for completed tasks (the executing engineer typically does this incrementally).

- [ ] **Step 2: Commit completed plan**

```bash
cd /Users/elmm12/.config/nvim && git add docs/superpowers/plans/2026-04-26-golang-ide.md && git commit -m "$(cat <<'EOF'
docs: mark Go IDE plan complete

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**Spec coverage check:**
- gopls tightening (spec §Components 1) → Task 2 ✓
- Neotest Go adapter (spec §Components 2) → Task 3 ✓
- ray-x/go.nvim (spec §Components 3) → Task 4 ✓
- Go-specific keymaps (spec §Components 4) → Task 5 ✓
- Go ftplugin (spec §Components 5) → Task 6 ✓
- Templ filetype (spec §Components 6) → Task 7 ✓
- Delete dead debug.lua (spec §Components 7) → Task 8 ✓
- Manual testing checklist (spec §Testing) → Task 9 ✓

**Placeholder scan:** No "TBD"/"TODO"/"add appropriate"/"similar to". All code blocks contain literal Lua. All commands are exact.

**Type/name consistency:**
- `lsp_cfg = false` referenced in Task 4 Step 5 matches Task 4 Step 1 opts.
- Keymap prefix `<leader>cg` consistent in spec, Task 5, and Task 9 checklist.
- File paths consistent: `lua/plugins/lang/golang.lua`, `lua/plugins/neotest.lua`, `ftplugin/go.lua`, `lua/config/autocmds.lua`, `lua/plugins/debug.lua`.
- Plugin names consistent: `fredrikaverpil/neotest-golang`, `ray-x/go.nvim`, `ray-x/guihua.lua`, `leoluz/nvim-dap-go`.
