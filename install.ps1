# PowerShell Profile & Environment Auto-Installer
# =============================================================================
# GitHub One-Liner (Run this to install/update):
# irm https://raw.githubusercontent.com/SiliconeShojo/Supercharged-Terminal/main/install.ps1 | iex
# =============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Configuration
$RepoUrl = "https://raw.githubusercontent.com/SiliconeShojo/Supercharged-Terminal/main"
$LogFile = Join-Path $env:TEMP "pwsh_setup.log"

# Setup logging
function Write-Log { 
    param($Msg, $Color = "White", $Prefix = "i") 
    Write-Host "[$Prefix] $Msg" -ForegroundColor $Color
    "[$(Get-Date -Format 'HH:mm:ss')] [$Prefix] $Msg" | Out-File $LogFile -Append 
}

# 0. Initial Checks
Clear-Content $LogFile -ErrorAction SilentlyContinue
Write-Host "`n=====================================================" -ForegroundColor Magenta
Write-Host "   PowerShell Profile & Environment Auto-Installer   " -ForegroundColor Magenta
Write-Host "=====================================================`n" -ForegroundColor Magenta

# Internet Check
Write-Log "Verifying internet connection..."
try {
    $null = Invoke-WebRequest -Uri "https://www.google.com" -Method Head -TimeoutSec 5 -ErrorAction Stop
    Write-Log "Connectivity verified." "Green" "+"
}
catch {
    Write-Log "Internet connection failed. Please check your network." "Red" "-"
    return
}

# 1. Admin Privileges & Auto-Elevation
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "Elevating to Administrator..." "Yellow" "!"
    $ArgList = "-NoProfile -ExecutionPolicy Bypass -File `"$($PSCommandPath ?? (Join-Path $env:TEMP 'install_temp.ps1'))`""
    if (-not $PSCommandPath) {
        Invoke-WebRequest -Uri "$RepoUrl/install.ps1" -OutFile (Join-Path $env:TEMP "install_temp.ps1")
    }
    Start-Process pwsh -ArgumentList $ArgList -Verb RunAs
    exit
}
Write-Log "Admin privileges active." "Green" "+"

# 2. Dependency Installation (Winget)
$tools = @(
    @{ Id = "Microsoft.PowerShell"; Name = "PowerShell 7" },
    @{ Id = "JanDeDobbeleer.OhMyPosh"; Name = "Oh My Posh" },
    @{ Id = "sigoden.Dufs"; Name = "Dufs File Server" }
)

foreach ($tool in $tools) {
    Write-Log "Checking $($tool.Name)..."
    if (-not (winget list --id $tool.Id -e -q)) {
        Write-Log "Installing $($tool.Name)..." "Cyan"
        winget install --id $tool.Id --source winget --accept-package-agreements --accept-source-agreements | Out-Null
        Write-Log "$($tool.Name) installed." "Green" "+"
    }
    else {
        Write-Log "$($tool.Name) is already present." "Gray"
    }
}

# 3. Themes & Modules
Write-Log "Updating Oh My Posh themes..."
$ThemesDir = Join-Path $env:LOCALAPPDATA "Programs\oh-my-posh\themes"
New-Item -ItemType Directory -Path $ThemesDir -Force | Out-Null
try {
    $ZipPath = Join-Path $env:TEMP "themes.zip"
    Invoke-WebRequest -Uri "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip" -OutFile $ZipPath
    Expand-Archive -Path $ZipPath -DestinationPath $ThemesDir -Force
    Remove-Item $ZipPath -Force
    Write-Log "Themes synchronized." "Green" "+"
}
catch {
    Write-Log "Theme update failed, skipping." "Yellow" "!"
}

Write-Log "Installing PowerShell Gallery modules..."
$Modules = @('Terminal-Icons', 'PSReadLine')
foreach ($m in $Modules) {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Log "Installing $m..." "Cyan"
        Install-Module -Name $m -Scope CurrentUser -Force -AllowClobber | Out-Null
        Write-Log "$m ready." "Green" "+"
    }
}

# 4. Profile Installation
Write-Log "Installing Supercharged Profile..."
$ProfileDir = Split-Path -Parent $PROFILE
New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null

if (Test-Path $PROFILE) {
    Copy-Item $PROFILE "$PROFILE.bak" -Force
    Write-Log "Backup created: $(Split-Path $PROFILE -Leaf).bak" "Gray"
}

try {
    Invoke-WebRequest -Uri "$RepoUrl/Microsoft.PowerShell_profile.ps1" -OutFile $PROFILE -ErrorAction Stop
    Write-Log "Profile installed successfully." "Green" "+"
}
catch {
    Write-Log "Failed to download profile." "Red" "-"
}

Write-Host "`n=====================================================" -ForegroundColor Green
Write-Host "   Installation Complete! Please restart terminal.   " -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "   Logs: $LogFile" -ForegroundColor Gray

Write-Host "`nPress any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
