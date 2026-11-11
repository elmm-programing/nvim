# User-local Neovim install for Windows. No administrator rights.
#   irm https://raw.githubusercontent.com/elmm-programing/nvim/main/install.ps1 | iex
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$NvimVersion = "0.11.4"
$NodeVersion = "22.23.4"
$GoVersion = "1.27.3"
$RgVersion = "15.2.0"
$FdVersion = "10.5.1"
$LazyGitVersion = "0.66.2"
$Branch = "main"
$Repo = "https://github.com/elmm-programing/nvim.git"

$Prefix = Join-Path $env:LOCALAPPDATA "nvim-tools"
$Bin = Join-Path $Prefix "bin"
$Config = Join-Path $env:LOCALAPPDATA "nvim"
$GoBin = Join-Path $env:USERPROFILE "go\bin"

function Fail($Message) {
  Write-Error $Message
  exit 1
}

if ($env:PROCESSOR_ARCHITECTURE -ne "AMD64") {
  Fail "This installer supports 64-bit Windows (AMD64). This machine is $($env:PROCESSOR_ARCHITECTURE)."
}

function Test-Command($Name) {
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-VersionGe($Current, $Minimum) {
  if (-not $Current) { return $false }
  $left = ($Current -replace '^v', '') -replace '[^\d.].*$', ''
  $right = ($Minimum -replace '^v', '') -replace '[^\d.].*$', ''
  $l = @($left.Split("."))
  $r = @($right.Split("."))
  while ($l.Count -lt 3) { $l += "0" }
  while ($r.Count -lt 3) { $r += "0" }
  return ([version]($l[0..2] -join ".")) -ge ([version]($r[0..2] -join "."))
}

function Get-File($Url, $Dest) {
  Write-Host "Downloading $Url"
  $params = @{
    Uri = $Url
    OutFile = $Dest
    UseBasicParsing = $true
  }
  $proxy = $env:HTTPS_PROXY
  if (-not $proxy) { $proxy = $env:HTTP_PROXY }
  if ($proxy) { $params.Proxy = $proxy }
  Invoke-WebRequest @params
}

function Expand-Zip($Zip, $Dest) {
  if (Test-Path $Dest) { Remove-Item -Recurse -Force $Dest }
  New-Item -ItemType Directory -Force -Path $Dest | Out-Null
  Expand-Archive -Path $Zip -DestinationPath $Dest -Force
}

if (-not (Test-Command "git")) {
  Fail "git is required and was not found. Install git, then run this again."
}
if (-not (Test-Command "gcc") -and -not (Test-Command "clang") -and -not (Test-Command "cc")) {
  Write-Host "No C compiler found. Treesitter parsers will not build until gcc or clang is installed."
}

New-Item -ItemType Directory -Force -Path $Bin, $GoBin | Out-Null
$temp = Join-Path ([System.IO.Path]::GetTempPath()) ("nvim-install-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $temp | Out-Null

$haveNvim = $false
if (Test-Command "nvim") {
  $line = & nvim --version 2>$null | Select-Object -First 1
  if ($line -match '(\d+\.\d+\.\d+)') {
    $haveNvim = Test-VersionGe $Matches[1] "0.11.0"
  }
}
$haveNode = $false
if (Test-Command "node") {
  $nodeLine = & node -v 2>$null
  if ($nodeLine -match '(\d+\.\d+\.\d+)') {
    $haveNode = Test-VersionGe $Matches[1] "20.0.0"
  }
}
$haveGo = Test-Command "go"
$haveJava = $false
if ((Test-Command "java") -and (Test-Command "javac")) {
  $javaLine = (& java -version 2>&1 | Select-Object -First 1) -join ""
  if ($javaLine -match '"(\d+\.\d+\.\d+)') {
    $haveJava = Test-VersionGe $Matches[1] "17.0.0"
  }
}
$haveRg = Test-Command "rg"
$haveFd = Test-Command "fd"
$haveLazyGit = Test-Command "lazygit"

try {
  if ($haveNvim) {
    Write-Host "Neovim is already new enough."
  } else {
    $zip = Join-Path $temp "nvim.zip"
    Get-File "https://github.com/neovim/neovim/releases/download/v$NvimVersion/nvim-win64.zip" $zip
    Expand-Zip $zip (Join-Path $temp "nvim-src")
    if (Test-Path (Join-Path $Prefix "nvim")) { Remove-Item -Recurse -Force (Join-Path $Prefix "nvim") }
    Move-Item (Join-Path $temp "nvim-src\nvim-win64") (Join-Path $Prefix "nvim")
  }

  if ($haveNode) {
    Write-Host "Node is already new enough."
  } else {
    $zip = Join-Path $temp "node.zip"
    Get-File "https://nodejs.org/dist/v$NodeVersion/node-v$NodeVersion-win-x64.zip" $zip
    Expand-Zip $zip (Join-Path $temp "node-src")
    $extracted = Get-ChildItem (Join-Path $temp "node-src") -Directory | Select-Object -First 1
    if (Test-Path (Join-Path $Prefix "node")) { Remove-Item -Recurse -Force (Join-Path $Prefix "node") }
    Move-Item $extracted.FullName (Join-Path $Prefix "node")
  }

  if ($haveGo) {
    Write-Host "Go is already installed."
  } else {
    $zip = Join-Path $temp "go.zip"
    Get-File "https://go.dev/dl/go$GoVersion.windows-amd64.zip" $zip
    Expand-Zip $zip (Join-Path $temp "go-src")
    if (Test-Path (Join-Path $Prefix "go")) { Remove-Item -Recurse -Force (Join-Path $Prefix "go") }
    Move-Item (Join-Path $temp "go-src\go") (Join-Path $Prefix "go")
  }

  if ($haveJava) {
    Write-Host "Java is already new enough."
    $javaCmd = Get-Command javac -ErrorAction SilentlyContinue
    if ($javaCmd) {
      $javaHome = Split-Path (Split-Path $javaCmd.Source -Parent) -Parent
      if (Test-Path (Join-Path $javaHome "bin\java.exe")) {
        Set-Content -Path (Join-Path $Prefix "java-home") -Value $javaHome -Encoding ascii
      }
    }
  } else {
    $zip = Join-Path $temp "jdk.zip"
    Get-File "https://api.adoptium.net/v3/binary/latest/21/ga/windows/x64/jdk/hotspot/normal/eclipse?project=jdk" $zip
    Expand-Zip $zip (Join-Path $temp "jdk-src")
    $java = Get-ChildItem (Join-Path $temp "jdk-src") -Recurse -Filter "java.exe" | Select-Object -First 1
    if (-not $java) { Fail "JDK archive did not contain java.exe." }
    $jdkRoot = $java.Directory.Parent.FullName
    if (Test-Path (Join-Path $Prefix "jdk")) { Remove-Item -Recurse -Force (Join-Path $Prefix "jdk") }
    Move-Item $jdkRoot (Join-Path $Prefix "jdk")
    Set-Content -Path (Join-Path $Prefix "java-home") -Value (Join-Path $Prefix "jdk") -Encoding ascii
  }

  function Install-Bin($Name, $Url) {
    $zip = Join-Path $temp "$Name.zip"
    Get-File $Url $zip
    $dest = Join-Path $temp "$Name-src"
    Expand-Zip $zip $dest
    $found = Get-ChildItem $dest -Recurse -Filter "$Name.exe" | Select-Object -First 1
    if (-not $found) { Fail "Archive for $Name did not contain $Name.exe." }
    Copy-Item $found.FullName (Join-Path $Bin "$Name.exe") -Force
  }

  if ($haveRg) {
    Write-Host "ripgrep is already installed."
  } else {
    Install-Bin "rg" "https://github.com/BurntSushi/ripgrep/releases/download/$RgVersion/ripgrep-$RgVersion-x86_64-pc-windows-msvc.zip"
  }
  if ($haveFd) {
    Write-Host "fd is already installed."
  } else {
    Install-Bin "fd" "https://github.com/sharkdp/fd/releases/download/v$FdVersion/fd-v$FdVersion-x86_64-pc-windows-msvc.zip"
  }
  if ($haveLazyGit) {
    Write-Host "lazygit is already installed."
  } else {
    Install-Bin "lazygit" "https://github.com/jesseduffield/lazygit/releases/download/v$LazyGitVersion/lazygit_${LazyGitVersion}_windows_x86_64.zip"
  }
} finally {
  if (Test-Path $temp) { Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue }
}

$entries = @($Bin, $GoBin)
foreach ($dir in @(
    (Join-Path $Prefix "nvim\bin"),
    (Join-Path $Prefix "node"),
    (Join-Path $Prefix "go\bin"),
    (Join-Path $Prefix "jdk\bin")
  )) {
  if (Test-Path $dir) { $entries += $dir }
}
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$parts = @()
if ($userPath) {
  $parts = @($userPath.Split(";", [System.StringSplitOptions]::RemoveEmptyEntries))
}
foreach ($entry in $entries) {
  $already = $false
  foreach ($part in $parts) {
    if ($part.TrimEnd("\") -eq $entry.TrimEnd("\")) { $already = $true }
  }
  if (-not $already) { $parts = ,$entry + $parts }
}
[Environment]::SetEnvironmentVariable("Path", ($parts -join ";"), "User")
[Environment]::SetEnvironmentVariable("GOBIN", $GoBin, "User")
$jdkHome = Join-Path $Prefix "jdk"
if (Test-Path (Join-Path $jdkHome "bin\java.exe")) {
  [Environment]::SetEnvironmentVariable("JAVA_HOME", $jdkHome, "User")
  $env:JAVA_HOME = $jdkHome
}
$env:Path = ($entries + @($env:Path)) -join ";"
$env:GOBIN = $GoBin

if (Test-Path $Config) {
  Write-Host "Config already exists at $Config. Leaving it in place."
  Write-Host "Update it yourself, then open nvim and run :Lazy sync and :Mason."
  Write-Host "Open a new terminal so PATH is picked up."
  exit 0
}

& git clone --branch $Branch --depth 1 $Repo $Config
if ($LASTEXITCODE -ne 0) { Fail "git clone failed." }

$nvim = Join-Path $Prefix "nvim\bin\nvim.exe"
if (-not (Test-Path $nvim)) {
  $cmd = Get-Command nvim -ErrorAction SilentlyContinue
  if (-not $cmd) { Fail "nvim was not installed and is not on PATH." }
  $nvim = $cmd.Source
}

function Invoke-Nvim([string]$ArgumentString) {
  $empty = New-TemporaryFile
  $out = New-TemporaryFile
  $err = New-TemporaryFile
  # One string so Windows PowerShell 5.1 keeps quoted arguments together.
  $proc = Start-Process -FilePath $nvim -ArgumentList $ArgumentString -Wait -PassThru `
    -RedirectStandardInput $empty.FullName `
    -RedirectStandardOutput $out.FullName `
    -RedirectStandardError $err.FullName
  Get-Content $out.FullName, $err.FullName | Write-Host
  $code = $proc.ExitCode
  Remove-Item $empty.FullName, $out.FullName, $err.FullName -ErrorAction SilentlyContinue
  if ($code -ne 0) { Fail "nvim exited with code $code" }
}

$env:GIT_TERMINAL_PROMPT = "0"
Invoke-Nvim '--headless "+Lazy! sync" +qa'
$env:NVIM_MASON_SYNC = Join-Path $Config "install\mason-sync.lua"
Invoke-Nvim '--headless +lua dofile(os.getenv(''NVIM_MASON_SYNC''))'

Write-Host ""
Write-Host "Installed. Open a new terminal so PATH is picked up, then run: nvim"
