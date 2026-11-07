#!/usr/bin/env bash
# User-local Neovim install for Ubuntu and macOS. No sudo.
#   curl -fsSL https://raw.githubusercontent.com/elmm-programing/nvim/cursor/video-nvim-citrix-499f/install.sh | bash
set -euo pipefail

NVIM_VERSION=0.11.4
NODE_VERSION=22.23.4
GO_VERSION=1.27.3
RG_VERSION=15.2.0
FD_VERSION=10.5.1
LAZYGIT_VERSION=0.66.2
BRANCH=cursor/video-nvim-citrix-499f
REPO=https://github.com/elmm-programing/nvim.git

PREFIX="${HOME}/.local/nvim-tools"
BIN="${PREFIX}/bin"
CONFIG="${HOME}/.config/nvim"

die() {
  printf '%s\n' "$1" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

version_ge() {
  # $1 >= $2, dotted numeric versions. Works on bash 3.2 with set -u.
  local i c m
  local IFS=.
  local -a cur min
  read -r -a cur <<< "$1"
  read -r -a min <<< "$2"
  for i in 0 1 2; do
    c=0
    m=0
    if [ "$i" -lt "${#cur[@]}" ]; then
      c="${cur[$i]}"
    fi
    if [ "$i" -lt "${#min[@]}" ]; then
      m="${min[$i]}"
    fi
    c="$(printf '%s' "$c" | tr -cd '0-9')"
    m="$(printf '%s' "$m" | tr -cd '0-9')"
    [ -n "$c" ] || c=0
    [ -n "$m" ] || m=0
    if [ "$c" -gt "$m" ]; then
      return 0
    fi
    if [ "$c" -lt "$m" ]; then
      return 1
    fi
  done
  return 0
}

download() {
  local url="$1" dest="$2"
  echo "Downloading $url"
  curl -fL --retry 3 --retry-delay 2 -o "$dest" "$url"
}

extract_tar() {
  local archive="$1" dest="$2"
  mkdir -p "$dest"
  tar -xzf "$archive" -C "$dest"
}

case "$(uname -s)" in
  Linux) os=linux ;;
  Darwin) os=mac ;;
  *) die "This script supports Linux and macOS. On Windows, run install.ps1." ;;
esac

case "$(uname -m)" in
  x86_64 | amd64) cpu=x64 ;;
  arm64 | aarch64) cpu=arm64 ;;
  *) die "Unsupported CPU: $(uname -m)" ;;
esac

need_cmd curl || die "curl is required."
need_cmd tar || die "tar is required."
need_cmd git || die "git is required and was not found. Install git, then run this again."

if ! need_cmd gcc && ! need_cmd clang && ! need_cmd cc; then
  echo "No C compiler found. Treesitter parsers will not build until gcc or clang is installed."
fi

mkdir -p "$BIN" "${HOME}/go/bin"

have_nvim=0
if need_cmd nvim; then
  nvim_ver="$(nvim --version 2>/dev/null | awk 'NR==1 { print $2 }' | sed 's/^v//')"
  if version_ge "$nvim_ver" "0.11.0"; then
    have_nvim=1
  fi
fi

have_node=0
if need_cmd node; then
  node_ver="$(node -v 2>/dev/null | sed 's/^v//')"
  if version_ge "$node_ver" "20.0.0"; then
    have_node=1
  fi
fi

have_go=0
if need_cmd go && go version >/dev/null 2>&1; then
  have_go=1
fi

have_java=0
if need_cmd java; then
  java_ver="$(java -version 2>&1 | awk -F\" 'NR==1 { print $2 }')"
  if version_ge "$java_ver" "17.0.0"; then
    have_java=1
  fi
fi

have_rg=0
need_cmd rg && have_rg=1
have_fd=0
need_cmd fd && have_fd=1
have_lazygit=0
need_cmd lazygit && have_lazygit=1

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

if [ "$have_nvim" -eq 1 ]; then
  echo "Neovim $(nvim --version | awk 'NR==1 { print $2 }') is already new enough."
else
  case "${os}-${cpu}" in
    linux-x64) nvim_asset="nvim-linux-x86_64.tar.gz" ;;
    linux-arm64) nvim_asset="nvim-linux-arm64.tar.gz" ;;
    mac-x64) nvim_asset="nvim-macos-x86_64.tar.gz" ;;
    mac-arm64) nvim_asset="nvim-macos-arm64.tar.gz" ;;
  esac
  download "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/${nvim_asset}" "$tmp/nvim.tar.gz"
  rm -rf "$tmp/nvim-src" "$PREFIX/nvim"
  extract_tar "$tmp/nvim.tar.gz" "$tmp/nvim-src"
  mv "$tmp/nvim-src"/nvim-* "$PREFIX/nvim"
  ln -sfn "$PREFIX/nvim/bin/nvim" "$BIN/nvim"
fi

if [ "$have_node" -eq 1 ]; then
  echo "Node $(node -v) is already new enough."
else
  case "${os}-${cpu}" in
    linux-x64) node_triple="linux-x64" ;;
    linux-arm64) node_triple="linux-arm64" ;;
    mac-x64) node_triple="darwin-x64" ;;
    mac-arm64) node_triple="darwin-arm64" ;;
  esac
  download "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-${node_triple}.tar.gz" "$tmp/node.tar.gz"
  rm -rf "$tmp/node-src" "$PREFIX/node"
  extract_tar "$tmp/node.tar.gz" "$tmp/node-src"
  mv "$tmp/node-src"/node-v* "$PREFIX/node"
fi

if [ "$have_go" -eq 1 ]; then
  echo "Go is already installed."
else
  case "${os}-${cpu}" in
    linux-x64) go_triple="linux-amd64" ;;
    linux-arm64) go_triple="linux-arm64" ;;
    mac-x64) go_triple="darwin-amd64" ;;
    mac-arm64) go_triple="darwin-arm64" ;;
  esac
  download "https://go.dev/dl/go${GO_VERSION}.${go_triple}.tar.gz" "$tmp/go.tar.gz"
  rm -rf "$tmp/go-src" "$PREFIX/go"
  extract_tar "$tmp/go.tar.gz" "$tmp/go-src"
  mv "$tmp/go-src/go" "$PREFIX/go"
fi

if [ "$have_java" -eq 1 ]; then
  echo "Java ${java_ver} is already new enough."
else
  case "${os}-${cpu}" in
    linux-x64) jdk_os="linux"; jdk_arch="x64" ;;
    linux-arm64) jdk_os="linux"; jdk_arch="aarch64" ;;
    mac-x64) jdk_os="mac"; jdk_arch="x64" ;;
    mac-arm64) jdk_os="mac"; jdk_arch="aarch64" ;;
  esac
  download "https://api.adoptium.net/v3/binary/latest/21/ga/${jdk_os}/${jdk_arch}/jdk/hotspot/normal/eclipse?project=jdk" "$tmp/jdk.tar.gz"
  rm -rf "$tmp/jdk-src" "$PREFIX/jdk"
  extract_tar "$tmp/jdk.tar.gz" "$tmp/jdk-src"
  java_bin="$(find "$tmp/jdk-src" -type f -path '*/bin/java' | head -n 1)"
  [ -n "$java_bin" ] || die "JDK archive did not contain bin/java."
  mv "$(dirname "$(dirname "$java_bin")")" "$PREFIX/jdk"
fi

install_bin() {
  local name="$1" url="$2"
  download "$url" "$tmp/${name}.tar.gz"
  rm -rf "$tmp/${name}-src"
  extract_tar "$tmp/${name}.tar.gz" "$tmp/${name}-src"
  local found
  found="$(find "$tmp/${name}-src" -type f -name "$name" | head -n 1)"
  [ -n "$found" ] || die "Archive for ${name} did not contain a ${name} binary."
  cp "$found" "$BIN/${name}"
  chmod +x "$BIN/${name}"
}

if [ "$have_rg" -eq 1 ]; then
  echo "ripgrep is already installed."
else
  case "${os}-${cpu}" in
    linux-x64) rg_asset="ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz" ;;
    linux-arm64) rg_asset="ripgrep-${RG_VERSION}-aarch64-unknown-linux-musl.tar.gz" ;;
    mac-x64) rg_asset="ripgrep-${RG_VERSION}-x86_64-apple-darwin.tar.gz" ;;
    mac-arm64) rg_asset="ripgrep-${RG_VERSION}-aarch64-apple-darwin.tar.gz" ;;
  esac
  install_bin rg "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/${rg_asset}"
fi

if [ "$have_fd" -eq 1 ]; then
  echo "fd is already installed."
else
  case "${os}-${cpu}" in
    linux-x64) fd_asset="fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz" ;;
    linux-arm64) fd_asset="fd-v${FD_VERSION}-aarch64-unknown-linux-musl.tar.gz" ;;
    mac-x64) fd_asset="fd-v${FD_VERSION}-x86_64-apple-darwin.tar.gz" ;;
    mac-arm64) fd_asset="fd-v${FD_VERSION}-aarch64-apple-darwin.tar.gz" ;;
  esac
  install_bin fd "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/${fd_asset}"
fi

if [ "$have_lazygit" -eq 1 ]; then
  echo "lazygit is already installed."
else
  case "${os}-${cpu}" in
    linux-x64) lg_asset="lazygit_${LAZYGIT_VERSION}_linux_x86_64.tar.gz" ;;
    linux-arm64) lg_asset="lazygit_${LAZYGIT_VERSION}_linux_arm64.tar.gz" ;;
    mac-x64) lg_asset="lazygit_${LAZYGIT_VERSION}_darwin_x86_64.tar.gz" ;;
    mac-arm64) lg_asset="lazygit_${LAZYGIT_VERSION}_darwin_arm64.tar.gz" ;;
  esac
  install_bin lazygit "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/${lg_asset}"
fi

cat > "${PREFIX}/env.sh" << 'EOF'
# Added by the nvim installer. Safe to source from bash or zsh.
export NVIM_TOOLS="${HOME}/.local/nvim-tools"
export GOBIN="${HOME}/go/bin"
export PATH="${NVIM_TOOLS}/bin:${NVIM_TOOLS}/node/bin:${NVIM_TOOLS}/go/bin:${GOBIN}:${PATH}"
if [ -x "${NVIM_TOOLS}/jdk/bin/java" ]; then
  export JAVA_HOME="${NVIM_TOOLS}/jdk"
  export PATH="${JAVA_HOME}/bin:${PATH}"
fi
EOF

snippet='# nvim-tools
[ -f "$HOME/.local/nvim-tools/env.sh" ] && . "$HOME/.local/nvim-tools/env.sh"'
for rc in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
  if [ -f "$rc" ] && grep -q 'nvim-tools/env.sh' "$rc"; then
    continue
  fi
  if [ -f "$rc" ] || [ "$rc" = "${HOME}/.bashrc" ] || [ "$rc" = "${HOME}/.zshrc" ]; then
    printf '\n%s\n' "$snippet" >> "$rc"
  fi
done

# shellcheck disable=SC1091
. "${PREFIX}/env.sh"
hash -r || true

if [ -e "$CONFIG" ]; then
  echo "Config already exists at ${CONFIG}. Leaving it in place."
  echo "Update it yourself, then open nvim and run :Lazy sync and :Mason."
  exit 0
fi

git clone --branch "$BRANCH" --depth 1 "$REPO" "$CONFIG"

export GIT_TERMINAL_PROMPT=0
nvim --headless "+Lazy! sync" +qa </dev/null
nvim --headless "+luafile ${CONFIG}/install/mason-sync.lua" </dev/null

echo
echo "Installed. Open a new terminal so PATH is picked up, then run: nvim"
