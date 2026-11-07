# Install on a Citrix work VM

Install from inside the VM. The scripts do not use admin rights and do not change the system PATH. They only change your user PATH.

`git` has to already be on the machine. Outbound HTTPS to GitHub, nodejs.org, go.dev, and the Adoptium JDK has to work. If the VM uses a proxy, set it before the command:

```bash
export HTTPS_PROXY=http://proxy.example:8080
export HTTP_PROXY=http://proxy.example:8080
```

On Windows PowerShell:

```powershell
$env:HTTPS_PROXY = "http://proxy.example:8080"
$env:HTTP_PROXY = "http://proxy.example:8080"
```

## One command

Ubuntu and macOS:

```bash
curl -fsSL https://raw.githubusercontent.com/elmm-programing/nvim/cursor/video-nvim-citrix-499f/install.sh | bash
```

Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/elmm-programing/nvim/cursor/video-nvim-citrix-499f/install.ps1 | iex
```

Open a new terminal when it finishes, then run `nvim`.

## What it installs

Tools go to `~/.local/nvim-tools` on Ubuntu and macOS, and to `%LOCALAPPDATA%\nvim-tools` on Windows. A tool is skipped when a new enough copy is already on `PATH`:

- Neovim 0.11 or newer. Otherwise Neovim 0.11.4 is downloaded.
- Node.js 20 or newer. Otherwise Node.js 22.
- Go, any version. Otherwise the current stable Go release.
- Java 17 or newer. Otherwise Temurin JDK 21. `JAVA_HOME` points at that JDK when this script installed it.
- `rg`, `fd`, and `lazygit` when the command is missing.

The config is cloned to `~/.config/nvim` (Windows: `%LOCALAPPDATA%\nvim`) from branch `cursor/video-nvim-citrix-499f`. If that folder already exists, it is left alone.

The script then runs `:Lazy sync` and `:MasonInstall` for the servers and tools in `lua/config/plugins/lsp.lua` and `lua/config/plugins/debugging.lua`, including `gopls`, `vtsls`, `jdtls`, `vue-language-server`, prettier, `eslint_d`, gofumpt, and delve. Mason stops after 15 minutes and prints anything still missing.

A C compiler is not installed. Telescope's fzf-native build skips itself when `make` is missing. Treesitter parsers need `gcc` or `clang`.

## Fonts and clipboard

Icons need a Nerd Font. The reference setup uses PlemolJP Console NF. If the image blocks font install, Neovim still runs and those icons show as boxes.

Citrix clipboard redirection often fails. When the session is remote and no clipboard program is installed, this config copies through OSC 52. If a clipboard program exists but the paste still stays inside the VM, start Neovim with:

```bash
NVIM_FORCE_OSC52=1 nvim
```

The local terminal has to allow OSC 52. The Citrix client itself sometimes strips it. In that case yank stays inside the VM.

## After the first sync

```vim
:Lazy restore
:checkhealth
:LspInfo
```

Use [VERIFY.md](../VERIFY.md). Expected clients: `vtsls` on TypeScript and JavaScript, `vtsls` plus `vue_ls` on `.vue`, `gopls` on Go, `jdtls` on Java.
