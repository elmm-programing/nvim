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
curl -fsSL https://raw.githubusercontent.com/elmm-programing/nvim/main/install.sh | bash
```

Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/elmm-programing/nvim/main/install.ps1 | iex
```

Open a new terminal when it finishes, then run `nvim`.

## What it installs

Tools go to `~/.local/nvim-tools` on Ubuntu and macOS, and to `%LOCALAPPDATA%\nvim-tools` on Windows. A tool is skipped when a new enough copy is already on `PATH`:

- Neovim 0.11 or newer. Otherwise Neovim 0.11.4 is downloaded. Ubuntu's packaged Neovim is older than that. Starting `nvim` still loads this config, and the config switches to `~/.local/nvim-tools/nvim/bin/nvim` when that copy exists.
- Node.js 20 or newer. Otherwise Node.js 22.
- Go, any version. Otherwise the current stable Go release.
- A JDK 25 or newer (`java` and `javac`) to run jdtls. Current jdtls builds ship Java 25 class files, so a JDK 17 or 21 already on the machine is not enough to start the language server. Those older JDKs are still registered as project runtimes when they are installed. Otherwise the script downloads Temurin JDK 25. The launcher JDK path is written to `~/.local/nvim-tools/java-home`, so a desktop session that never sourced `JAVA_HOME` can still start jdtls. Neovim also checks `/usr/lib/jvm`, `/usr/bin/java`, and the login shell.
- `rg`, `fd`, and `lazygit` when the command is missing.

The config is cloned to `~/.config/nvim` (Windows: `%LOCALAPPDATA%\nvim`) from `main`. If that folder already exists, it is left alone.

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
