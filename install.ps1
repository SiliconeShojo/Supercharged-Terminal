<#
    .DESCRIPTION
    "Supercharged Terminal" - Automated Installer
    Installs: PowerShell 7, Git, Oh-My-Posh, Modules, and Profile.
#>

# 1. AUTO-ELEVATE TO ADMIN
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Elevating to Administrator..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

Write-Host "🚀 STARTING SUPERCHARGED SETUP..." -ForegroundColor Cyan

# 2. CHECK POWERSHELL VERSION
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "⚠️  You are running PowerShell 5." -ForegroundColor Yellow
    Write-Host "   Installing PowerShell 7 now..." -ForegroundColor Cyan
    winget install --id Microsoft.PowerShell --source winget --accept-package-agreements --accept-source-agreements --silent
    
    Write-Host "`n✅ PowerShell 7 Installed!" -ForegroundColor Green
    Write-Host "PLEASE CLOSE THIS WINDOW." -ForegroundColor Red
    Write-Host "Open the new 'PowerShell 7' (Black Icon) and run this script again to finish the rest." -ForegroundColor Red
    Pause
    Exit
}

# 3. INSTALL TOOLS (Winget)
Write-Host "`n📦 Installing Essential Tools..." -ForegroundColor Cyan
winget install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements
winget install --id JanDeDobbeleer.OhMyPosh -e --silent --accept-package-agreements --accept-source-agreements
winget install --id gsudo -e --silent --accept-package-agreements --accept-source-agreements
winget install --id fastfetch -e --silent --accept-package-agreements --accept-source-agreements

# 4. CONFIGURE GIT (Safety Net)
Write-Host "`n🛡️  Configuring Git Safety Net..." -ForegroundColor Cyan
git config --global core.editor "notepad"

# 5. INSTALL MODULES
Write-Host "`n🔌 Installing PowerShell Modules..." -ForegroundColor Cyan
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Install-Module -Name Terminal-Icons -Repository PSGallery -Force -SkipPublisherCheck
Install-Module -Name PSReadLine -Repository PSGallery -Force -AllowPrerelease -SkipPublisherCheck

# 6. SETUP THEMES
Write-Host "`n🎨 Downloading Themes..." -ForegroundColor Cyan
$themePath = "$env:LOCALAPPDATA\Programs\oh-my-posh\themes"
if (!(Test-Path $themePath)) { New-Item -ItemType Directory -Path $themePath -Force | Out-Null }

Invoke-WebRequest -Uri "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip" -OutFile "$themePath\themes.zip"
Expand-Archive -Path "$themePath\themes.zip" -DestinationPath $themePath -Force
Remove-Item "$themePath\themes.zip"

# 7. WRITE PROFILE
Write-Host "`n📝 Writing your new Profile..." -ForegroundColor Cyan

$profilePath = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
$profileDir = Split-Path $profilePath

# HANDLER: Ensure directory exists before writing
if (!(Test-Path $profileDir)) { 
    Write-Host "   Creating missing directory: $profileDir" -ForegroundColor Gray
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null 
}

$ProfileContent = @'
# -------------------------------
# 1. Modules & Setup
# -------------------------------
Import-Module -Name Terminal-Icons
Import-Module -Name PSReadLine

# Theme Configuration
$env:POSH_THEMES_PATH = "$env:LOCALAPPDATA\Programs\oh-my-posh\themes"
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\montys.omp.json" | Invoke-Expression

# -------------------------------
# 2. Intelligent Autocomplete
# -------------------------------
Set-PSReadLineOption -PredictionViewStyle InlineView
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# -------------------------------
# 3. Coder Utilities
# -------------------------------
function mkcd { param($Path) New-Item -ItemType Directory -Path $Path -Force | Out-Null; Set-Location $Path }
function touch { param($Path) if(Test-Path $Path){(Get-Item $Path).LastWriteTime=Get-Date}else{$null>$Path} }
function which { param($Name) Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source }
function update { winget upgrade --all }

function killport { 
    param([int]$Port)
    $process = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique
    if ($process) { Stop-Process -Id $process -Force; Write-Host "💀 Killed process on port $Port" -ForegroundColor Red }
    else { Write-Host "No process found on port $Port" -ForegroundColor Yellow }
}

function clh {
    # 1. Clear the specific PSReadLine "Ghost Text" memory
    [Microsoft.PowerShell.PSConsoleReadLine]::ClearHistory()

    # 2. Delete the persistent history file on disk
    Remove-Item (Get-PSReadLineOption).HistorySavePath -ErrorAction SilentlyContinue

    # 3. Clear the standard PowerShell session history
    Clear-History

    Write-Host "👻 Ghost Text & History VAPORIZED!" -ForegroundColor Green
}

# -------------------------------
# 4. Navigation & System
# -------------------------------
Set-Alias ll ls                 
Set-Alias grep Select-String    
Set-Alias sudo gsudo            

function ..   { Set-Location .. }
function ...  { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }

# [FIX] Smart Profile Editor
function pro { 
    $dir = Split-Path $PROFILE
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    if (!(Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
    notepad $PROFILE 
}

function ref { . $PROFILE; Write-Host "✔ Profile reloaded!" -ForegroundColor Green }

# -------------------------------
# 5. Git & Version Control
# -------------------------------
Set-Alias g git
function gs  { git status }
function gpl { git pull }
function gd  { git diff }
function gl  { git log --oneline --graph --decorate --all }

# [SMART] Update Repo (Vim-Proof & Empty-Check)
function gup {
    param ( [Parameter(Mandatory=$true)][string]$Message )
    
    $branch = git branch --show-current
    if (-not $branch) { Write-Error "❌ Not a git repo."; return }

    # Check if there are changes to commit
    if (-not (git status --porcelain)) {
        Write-Warning "⚠️  No changes found! Did you save your files?"
        Write-Host "   (Pulling anyway to ensure you are up to date...)" -ForegroundColor Gray
        git pull origin $branch --no-edit
        return
    }

    Write-Host "🚀 Updating branch '$branch'..." -ForegroundColor Cyan
    git add .
    git commit -m $Message
    
    Write-Host "⬇ Pulling..." -ForegroundColor Yellow
    git pull origin $branch --no-edit
    
    Write-Host "⬆ Pushing..." -ForegroundColor Magenta
    git push origin $branch
    
    Write-Host "✅ Done!" -ForegroundColor Green
}

function gstart {
    param ( [string]$RepoUrl )
    if (-not $RepoUrl) { Write-Error "❌ Provide Repo URL."; return }

    Write-Host "🚀 Initializing project..." -ForegroundColor Cyan
    git init
    Write-Host "➕ Adding all files..." -ForegroundColor Cyan
    git add .
    Write-Host "💾 Committing 'first commit'..." -ForegroundColor Cyan
    git commit -m "first commit"
    Write-Host "🌿 Renaming branch to main..." -ForegroundColor Cyan
    git branch -M main
    Write-Host "🔗 Adding remote origin $RepoUrl..." -ForegroundColor Cyan
    git remote add origin $RepoUrl
    Write-Host "⬆️  Pushing to origin main..." -ForegroundColor Magenta
    git push -u origin main
    Write-Host "✅ Repo started successfully!" -ForegroundColor Green
}

function gcl {
    param([string]$Url)
    
    if (-not $Url) { Write-Error "❌ Please provide a GitHub URL."; return }
    
    # 1. Clone the repo
    git clone $Url
    
    # 2. Extract folder name (e.g., 'repo.git' -> 'repo')
    $RepoName = ($Url -split '/')[-1] -replace '\.git$', ''
    
    # 3. Enter the folder automatically
    if (Test-Path $RepoName) { 
        Set-Location $RepoName
        Write-Host "📂 Entered '$RepoName'" -ForegroundColor Cyan
        ls
    }
}

# -------------------------------
# 6. Help Menu
# -------------------------------
function shortcuts {
    Write-Host "`n⚡ COMMAND CHEAT SHEET" -ForegroundColor Magenta
    Write-Host "-----------------------------------------------------" -ForegroundColor DarkGray
    Write-Host " [GIT]" -ForegroundColor Cyan
    Write-Host "  gup <msg>       : Add + Commit + Pull + Push (Auto-Branch)"
    Write-Host "  gstart <url>    : Init, Commit & Push to new URL"
    Write-Host "  gcl <url>       : Clone & Enter Repo"
    Write-Host "  gpl             : Git Pull"
    Write-Host "  gs / gd / gl    : Status / Diff / Log Graph"
    Write-Host "`n [FILES & NAV]" -ForegroundColor Cyan
    Write-Host "  mkcd <name>     : Create folder and enter it"
    Write-Host "  touch <name>    : Create empty file"
    Write-Host "  ll              : List files with icons"
    Write-Host "  .. / ...        : Go up 1 or 2 levels"
    Write-Host "`n [SYSTEM]" -ForegroundColor Cyan
    Write-Host "  killport <port> : Kill process on port"
    Write-Host "  clh             : Clear all terminal history"
    Write-Host "  which <cmd>     : Find where a command is installed"
    Write-Host "  update          : Update all software (Winget)"
    Write-Host "  pro / ref       : Edit / Reload Profile"
    Write-Host "-----------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
}
Clear-Host
'@

Set-Content -Path $profilePath -Value $ProfileContent -Encoding UTF8

Write-Host "`n✅ SETUP COMPLETE!" -ForegroundColor Green
Write-Host "1. Restart your Terminal."
Write-Host "2. Enjoy your new Supercharged Shell!"
Pause