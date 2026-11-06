# Install on a Citrix work VM

This machine cannot reach the work desktop. Install from inside the VM, without admin rights. The config stays on lazy.nvim and does not need Neovim 0.12.

You need `git` already on the image, or a portable `git` you are allowed to run. Outbound HTTPS to GitHub and the Mason registries (GitHub, npm) has to work. If the VM uses a proxy, set it before every command below:

```bash
export HTTPS_PROXY=http://proxy.example:8080
export HTTP_PROXY=http://proxy.example:8080
```

On Windows PowerShell:

```powershell
$env:HTTPS_PROXY = "http://proxy.example:8080"
$env:HTTP_PROXY = "http://proxy.example:8080"
```

## Linux

Neovim 0.11 or newer, user-local:

```bash
mkdir -p ~/bin ~/src
curl -fsSL -o /tmp/nvim.tar.gz https://github.com/neovim/neovim/releases/download/v0.11.4/nvim-linux-x86_64.tar.gz
tar -xzf /tmp/nvim.tar.gz -C ~/src
ln -sf ~/src/nvim-linux-x86_64/bin/nvim ~/bin/nvim
```

Add `~/bin` to `PATH` in the shell startup file you are allowed to edit.

```bash
git clone https://github.com/elmm-programing/nvim.git ~/.config/nvim
nvim
```

The first launch runs Lazy and installs plugins. Then `:Mason` and wait until these are present: `vtsls`, `vue-language-server`, `gopls`, `jdtls`, prettier, `eslint_d`, gofumpt, delve.

`make` is optional. Telescope's fzf-native build skips itself when `make` is missing.

## Windows

Neovim 0.11 or newer, user-local. In PowerShell:

```powershell
$dir = Join-Path $env:LOCALAPPDATA "nvim-win64"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$zip = Join-Path $env:TEMP "nvim-win64.zip"
Invoke-WebRequest -Uri "https://github.com/neovim/neovim/releases/download/v0.11.4/nvim-win64.zip" -OutFile $zip
Expand-Archive -Path $zip -DestinationPath $dir -Force
```

The zip contains a `nvim-win64` folder. The executable is `$dir\nvim-win64\bin\nvim.exe`. Add that `bin` directory to the **user** PATH (Settings, Environment Variables, Path for your account). Do not change the system PATH.

```powershell
git clone https://github.com/elmm-programing/nvim.git "$env:LOCALAPPDATA\nvim"
nvim
```

Then the same `:Mason` check as on Linux.

## Tools the VM may not have

Download release binaries into `~/bin` or `%LOCALAPPDATA%\bin` and add that directory to the user PATH. No installer is required.

| Tool | Used for |
|---|---|
| `rg` (ripgrep) | `;r` and `<leader>fg` live grep. Without it, grep pickers do nothing useful. |
| `fd` | faster file search. Telescope falls back to its find command when `fd` is missing. |
| `lazygit` | `;g` float. The keymap tells you if the binary is missing. |
| Node.js | Mason language servers for Vue, TypeScript, and ESLint. A zip extract of Node is enough. |
| Go | `gopls` and Go tools. A zip extract, with `~/go/bin` on `PATH`. This config prepends `~/go/bin` when that directory exists. |
| JDK 17 or 21 | Java and `jdtls`. A zip extract is enough. `JAVA_HOME` must point at it. |

## Fonts and clipboard

Icons in the tabline, statusline, and completion menu need a Nerd Font. The reference setup uses PlemolJP Console NF. If the image blocks font install, Neovim still runs and those icons show as boxes.

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
