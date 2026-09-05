# nvim

Personal Neovim 0.11+ config for **Go**, **Java**, **Vue/Nuxt/TypeScript**, and **Rust**.
Not LazyVim. Tokyo Night, blink.cmp, Mason, no AI plugins.

## Install

```bash
git clone https://github.com/elmm-programing/nvim.git ~/.config/nvim
nvim
```

First launch runs `:Lazy sync` (plugin install) and Mason tool install. Need `git`, `make`, a Nerd Font, and language toolchains you actually use (`go`, JDK 17/21 via SDKMAN, Node for Vue/TS, `rustup`).

`main` and `Mac` are kept identical.

## After pulling

```vim
:Lazy restore
```

That uses `lazy-lock.json` so plugin versions stay pinned. Update with `:Lazy sync` and commit the lockfile.

## Tests

Use **neotest** only (`<leader>tt` nearest, `<leader>tf` file, `<leader>td` debug).
Go helpers (`<leader>G*`) are fill-struct / tags / `if err` / run — not a second test runner.

## Projects

`project.nvim` does **not** auto-chdir. Switch with `<leader>fp` (Telescope) or `<leader>fP` (set cwd to detected root).

## Colors

Tailwind / hex / rgb colors highlight in buffer via `nvim-highlight-colors` (blink.cmp, not nvim-cmp).

## Keymaps (short)

| Keys | Action |
|---|---|
| `<leader><leader>` / `<leader>/` | Files / grep |
| `<leader>e` | Neo-tree |
| `gd` `gr` `gi` `gy` `K` | LSP |
| `<leader>cI` / `:LspInfo` | LSP client status |
| `<leader>ca` `<leader>cr` `<leader>cf` | Code action / rename / format |
| `]b` `[b` | Buffers |
| `]c` `[c` | Next/prev class (Treesitter; `]]` is Vim sections) |
| `]m` `[m` | Next/prev function |
| `<leader>tt` | Nearest test |
| `<leader>Db` `<leader>Dc` | Breakpoint / continue |
| `<leader>uh` | Toggle inlay hints |
| `<leader>fp` / `<leader>fP` | Projects / set project root |

## Intentional

- **No Copilot / Gemini / Avante / Ollama.**
- **Snacks `image` is off.** Hover image preview crashes Treesitter on this stack.
- Files over 1MB use Snacks `bigfile` (Treesitter/LSP/format skipped).
- Prettier follows the project's `.prettierrc` (no hardcoded `--no-semi`).
- `jdtls` is started only by nvim-jdtls; `rust-analyzer` only by rustaceanvim.
