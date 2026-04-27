# PowerShell Profile & Environment Auto-Installer
# =============================================================================
# GitHub One-Liner (Run this to install/update):
# irm https://raw.githubusercontent.com/SiliconeShojo/Supercharged-Terminal/main/install.ps1 | iex
# =============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Configuration
$RepoBaseUrl = "https://raw.githubusercontent.com/SiliconeShojo/Supercharged-Terminal/main"
$LogFile = Join-Path $env:TEMP "pwsh_setup.log"

# Setup logging functions
function Write-PoshInfo { 
    param($Msg) 
    Write-Host "[i] $Msg" -ForegroundColor Cyan
    "[$(Get-Date -Format 'HH:mm:ss')] [INFO] $Msg" | Out-File $LogFile -Append 
}

function Write-PoshSuccess { 
    param($Msg) 
    Write-Host "[+] $Msg" -ForegroundColor Green
    "[$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] $Msg" | Out-File $LogFile -Append 
}

function Write-PoshWarn { 
    param($Msg) 
    Write-Host "[!] $Msg" -ForegroundColor Yellow
    "[$(Get-Date -Format 'HH:mm:ss')] [WARN] $Msg" | Out-File $LogFile -Append 
}

function Write-PoshError { 
    param($Msg) 
    Write-Host "[-] $Msg" -ForegroundColor Red
    "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] $Msg" | Out-File $LogFile -Append 
}

# 0. Initial Checks
Clear-Content $LogFile -ErrorAction SilentlyContinue

Write-Host "=====================================================" -ForegroundColor Magenta
Write-Host "   PowerShell Profile & Environment Auto-Installer   " -ForegroundColor Magenta
Write-Host "=====================================================" -ForegroundColor Magenta

# Check Internet Connection
Write-PoshInfo "Testing internet connectivity..."
try {
    Test-Connection -ComputerName www.google.com -Count 1 -ErrorAction Stop | Out-Null
    Write-PoshSuccess "Internet connection verified."
} catch {
    Write-PoshError "Internet connection is required. Please check your connection."
    return
}

# 1. Check for Administrative Privileges & Auto-Elevate
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-PoshInfo "Requesting Administrative privileges..."
    if ($PSCommandPath) {
        Start-Process pwsh -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    } else {
        Write-PoshWarn "Script is running in memory. Downloading to temp file for elevation..."
        $TempScript = Join-Path $env:TEMP "install_temp.ps1"
        Invoke-WebRequest -Uri "$RepoBaseUrl/install.ps1" -OutFile $TempScript -ErrorAction SilentlyContinue
        Start-Process pwsh -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$TempScript`"" -Verb RunAs
        exit
    }
}
Write-PoshSuccess "Admin privileges confirmed."

# 2. Install PowerShell 7 via Winget
Write-PoshInfo "Checking for PowerShell 7..."
if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
    Write-PoshInfo "Installing latest PowerShell 7..."
    winget install --id Microsoft.PowerShell --source winget --accept-package-agreements --accept-source-agreements
    Write-PoshSuccess "PowerShell 7 installed."
} else {
    Write-PoshSuccess "PowerShell 7 already installed."
}

# 3. Install Oh My Posh
Write-PoshInfo "Checking for Oh My Posh..."
if (-not (winget list --id JanDeDobbeleer.OhMyPosh -e -q)) {
    Write-PoshInfo "Installing Oh My Posh..."
    winget install --id JanDeDobbeleer.OhMyPosh --source winget --accept-package-agreements --accept-source-agreements
    Write-PoshSuccess "Oh My Posh installed."
} else {
    Write-PoshSuccess "Oh My Posh is already installed."
}

# Refresh PATH for the current session
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# 4. Oh My Posh Themes
$localAppData = $env:LOCALAPPDATA
$ThemesDir = Join-Path $localAppData "Programs\oh-my-posh\themes"
if (-not (Test-Path $ThemesDir)) {
    New-Item -ItemType Directory -Path $ThemesDir -Force | Out-Null
}

$ZipPath = Join-Path $env:TEMP "omp_themes.zip"
Write-PoshInfo "Updating themes..."
try {
    $ThemeUrl = "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip"
    Invoke-WebRequest -Uri $ThemeUrl -OutFile $ZipPath -ErrorAction Stop
    Expand-Archive -Path $ZipPath -DestinationPath $ThemesDir -Force
    Remove-Item -Path $ZipPath -Force
    Write-PoshSuccess "Themes updated."
} catch {
    Write-PoshWarn "Could not update themes. Proceeding with existing ones."
}

# 5. PowerShell Gallery Modules
Write-PoshInfo "Installing required PowerShell modules..."
$Modules = @('Terminal-Icons', 'PSReadLine')
foreach ($Module in $Modules) {
    if (-not (Get-Module -ListAvailable -Name $Module)) {
        Write-PoshInfo "Installing module: $Module..."
        try {
            Install-Module -Name $Module -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
            Write-PoshSuccess "Module $Module installed."
        } catch {
            Write-PoshError "Failed to install module $Module."
        }
    } else {
        Write-PoshSuccess "Module $Module is already present."
    }
}

# 6. Install File Server Engine (Dufs)
Write-PoshInfo "Checking for File Server Engine (Dufs)..."
if (-not (Get-Command dufs -ErrorAction SilentlyContinue)) {
    Write-PoshInfo "Installing Dufs..."
    winget install --id sigoden.Dufs --source winget --accept-package-agreements --accept-source-agreements
    Write-PoshSuccess "Dufs installed."
} else {
    Write-PoshSuccess "Dufs already installed."
}

# 7. Profile Installation & Backup
Write-PoshInfo "Setting up PowerShell profile..."
$ProfilePath = $PROFILE
$ProfileDir = Split-Path -Parent $ProfilePath
$TempProfile = Join-Path $env:TEMP "profile_download.ps1"

if (-not (Test-Path $ProfileDir)) {
    New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
}

$ProfileExists = Test-Path $ProfilePath

Write-PoshInfo "Downloading new profile from GitHub..."
try
{
    $TargetUrl = "$RepoBaseUrl/Microsoft.PowerShell_profile.ps1"
    Invoke-WebRequest -Uri $TargetUrl -OutFile $TempProfile -ErrorAction Stop
    
    if ($ProfileExists) {
        $BackupPath = Join-Path $ProfileDir "Microsoft.PowerShell_profile.ps1.bak"
        Write-PoshInfo "Backing up existing profile to $(Split-Path $BackupPath -Leaf)"
        Copy-Item -Path $ProfilePath -Destination $BackupPath -Force
    }

    Move-Item -Path $TempProfile -Destination $ProfilePath -Force
    
    if ($ProfileExists) {
        Write-PoshSuccess "Profile updated successfully from GitHub."
    }
    else {
        Write-PoshSuccess "Profile installed successfully from GitHub."
    }
}
catch
{
    Write-PoshError "Could not fetch profile from GitHub."
    Write-PoshError "Details: $($_.Exception.Message)"
    if (Test-Path $TempProfile) { Remove-Item $TempProfile -Force }
}

Write-Host "`n=====================================================" -ForegroundColor Green
Write-Host "   Installation Complete! Please restart terminal.   " -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "   Logs saved to: $LogFile" -ForegroundColor Gray

Write-Host "`nPress any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
