# nvim

Personal Neovim 0.11+ config for **Vue/Nuxt**, **JavaScript**, **TypeScript**, **Java**, and **Go**.
Not LazyVim. Solarized Osaka, blink.cmp, Mason, no Copilot.

Citrix or another locked-down desktop: [docs/citrix.md](docs/citrix.md). No admin install.

## Install

One command. It does not need admin rights. `git` must already be installed. A proxy already set in `HTTPS_PROXY` is used.

Ubuntu and macOS:

```bash
curl -fsSL https://raw.githubusercontent.com/elmm-programing/nvim/cursor/video-nvim-citrix-499f/install.sh | bash
```

Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/elmm-programing/nvim/cursor/video-nvim-citrix-499f/install.ps1 | iex
```

The script installs Neovim 0.11.4, Node 22, Go, Temurin JDK 21, ripgrep, fd, and lazygit into your user account when those tools are missing or too old. It then clones this config and installs the Mason language servers and formatters. Open a new terminal and run `nvim`.

Citrix and the full list of what is skipped when a tool is already present: [docs/citrix.md](docs/citrix.md).

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
| `;f` `;r` `;;` `\\` | Files (hidden) / live grep (hidden) / resume / buffers |
| `;e` `;n` `;h` `;g` | Diagnostics / notifier history / git hunks / lazygit |
| `<leader>e` / `<leader>sf` | Neo-tree / oil float with preview |
| `gd` `gr` `gi` `gy` `K` | LSP (`gd` stays definition) |
| `<leader>cI` / `:LspInfo` | LSP client status |
| `<leader>ca` `<leader>cr` `<leader>cf` | Code action / rename / format |
| `:ToggleFormatter` | Format on save for this buffer |
| `<leader>gb` `<leader>gB` | Line blame / buffer blame |
| `<leader>gh` `<leader>gs` | Stage hunk / stage buffer |
| `<leader>gd` `<leader>gv` `<leader>gH` | Diff overlay / diff view / file history |
| `<leader>gy` | Copy a GitHub link |
| `<leader>yf` `<leader>yp` | Copy `path#Lline` / absolute |
| `<leader>jp` | `package.json` float |
| `]b` `[b` | Buffers |
| `]c` `[c` | Next/prev class (Treesitter) |
| `]]` `[[` | Next/prev word under the cursor, once an LSP is attached |
| `]m` `[m` | Next/prev function |
| `<leader>tt` | Nearest test |
| `<leader>Db` `<leader>Dc` | Breakpoint / continue |
| `<leader>uh` | Toggle inlay hints |
| `<leader>fp` / `<leader>fP` | Projects / set project root |

## Intentional

- **No Copilot / Gemini / Avante / Ollama.**
- **Not a Neovim 0.12 rewrite.** `vim.pack`, ui2, and `:restart` are not used, so the config still starts language servers on older Neovim.
- **Snacks `image` is off.** Hover image preview crashes Treesitter on this stack.
- Files over 1MB use Snacks `bigfile` (Treesitter/LSP/format skipped).
- Prettier follows the project's `.prettierrc` (no hardcoded `--no-semi`).
- `jdtls` is started only by nvim-jdtls; `rust-analyzer` only by rustaceanvim.
