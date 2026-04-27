# Advanced PowerShell Profile Configuration
# Standardized developer environment with git enhancements, system utilities,
# and a custom interface system.

# Store the actual path of this script for the 'ref' command
$Global:ProfileSourcePath = $PSCommandPath

# =============================================================================
# >>>  CORE ENVIRONMENT & PERFORMANCE                                      <<<
# =============================================================================

# Force UTF-8 encoding for high-fidelity icon rendering
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Advanced Performance Flags
$env:POSH_GIT_STATUS_ASYNC = 1
$env:POSH_THEME_CACHING = 1     # Faster startup
$env:POSH_THEMES_PATH = Join-Path $env:LOCALAPPDATA "Programs\oh-my-posh\themes"

# =============================================================================
# >>>  SAFE ICON DEFINITIONS (PS 5.1 COMPATIBLE)                           <<<
# =============================================================================

$IconOk = [string][char]::ConvertFromUtf32(0xF012C) # 󰄬
$IconInfo = [string][char]::ConvertFromUtf32(0xF02FD) # 󰋽
$IconWarn = [string][char]::ConvertFromUtf32(0xF11CE) # 󱇎
$IconFail = [string][char]::ConvertFromUtf32(0xF0156) # 󰅖
$IconBusy = [string][char]::ConvertFromUtf32(0xF1454) # 󱑔
$IconArrow = [string][char]::ConvertFromUtf32(0x279C)  # ➜
$LineChar = [string][char]0x2501                     # ━

# =============================================================================
# >>>  INTERFACE & FEEDBACK SYSTEM                                         <<<
# =============================================================================

function Write-Success {
    # Writes a success message with an 'OK' icon.
    param([string]$msg)
    Write-Host "  [ " -NoNewline
    Write-Host "$IconOk OK" -ForegroundColor Green -NoNewline
    Write-Host " ] $msg"
}

function Write-Info {
    # Writes an informational message with an 'INFO' icon.
    param([string]$msg)
    Write-Host "  [ " -NoNewline
    Write-Host "$IconInfo INFO" -ForegroundColor Cyan -NoNewline
    Write-Host " ] $msg"
}

function Write-Alert {
    # Writes a warning message with a 'WARN' icon.
    param([string]$msg)
    Write-Host "  [ " -NoNewline
    Write-Host "$IconWarn WARN" -ForegroundColor Yellow -NoNewline
    Write-Host " ] $msg"
}

function Write-Failure {
    # Writes an error message with a 'FAIL' icon.
    param([string]$msg)
    Write-Host "  [ " -NoNewline
    Write-Host "$IconFail FAIL" -ForegroundColor Red -NoNewline
    Write-Host " ] $msg"
}

function Write-Action {
    # Writes a busy/action message with a 'BUSY' icon.
    param([string]$msg)
    Write-Host "  [ " -NoNewline
    Write-Host "$IconBusy BUSY" -ForegroundColor Magenta -NoNewline
    Write-Host " ] $msg"
}

# =============================================================================
# >>>  SHELL ENGINE & MODULES                                              <<<
# =============================================================================

if ((Get-Module -ListAvailable -Name PSReadLine)) {
    Import-Module -Name PSReadLine -WarningAction SilentlyContinue
    $psrlCmd = Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue
    if ($null -ne $psrlCmd) {
        Set-PSReadLineOption -ShowToolTips:$false -EditMode Windows -BellStyle None -CompletionQueryItems 100
        $params = $psrlCmd.Parameters
        if ($params.ContainsKey('PredictionViewStyle')) { Set-PSReadLineOption -PredictionViewStyle InlineView }
        if ($params.ContainsKey('PredictionSource')) { Set-PSReadLineOption -PredictionSource History }
        if ($params.ContainsKey('EnableMouseSupport')) { Set-PSReadLineOption -EnableMouseSupport:$false }
        if ($params.ContainsKey('AnimateMatchingParen')) { Set-PSReadLineOption -AnimateMatchingParen:$false }
        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
        Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
        Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    }
}

if ((Get-Command 'oh-my-posh' -ErrorAction SilentlyContinue)) {
    $ThemePath = Join-Path $env:POSH_THEMES_PATH "montys.omp.json"
    if (Test-Path $ThemePath) { oh-my-posh init pwsh --config $ThemePath | Invoke-Expression }
}

if ((Get-Module -ListAvailable -Name Terminal-Icons)) {
    Import-Module -Name Terminal-Icons -WarningAction SilentlyContinue
}

# =============================================================================
# >>>  DEVELOPER UTILITIES: NAVIGATION & FS                                <<<
# =============================================================================

function Initialize-Directory {
    # Creates a directory and enters it.
    param([Parameter(Mandatory)][string]$Path)
    Write-Action "Creating directory structure: $Path"
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    Set-Location $Path
    Write-Success "Directory ready and active: $(Get-Location)"
}
Set-Alias mkcd Initialize-Directory

function Set-TouchFile {
    # Updates the timestamp of a file or creates it if it doesn't exist.
    param([Parameter(Mandatory)][string]$Path)
    if (Test-Path $Path) { 
        (Get-Item $Path).LastWriteTime = Get-Date
        Write-Info "Updated timestamp for existing file: $Path" 
    } else { 
        New-Item -ItemType File -Path $Path -Force | Out-Null
        Write-Success "New file created: $Path" 
    }
}
Set-Alias touch Set-TouchFile

function Select-FileText {
    # Searches for a text pattern within files, excluding common development folders.
    param([Parameter(Mandatory)][string]$Pattern, [string]$Path = ".", [int]$MaxDepth = 3)
    Write-Host "  $IconInfo Arguments: <path> | -MaxDepth 5" -ForegroundColor Cyan
    $Ignore = '\\(\.git|node_modules|\.next|bin|obj|dist|build|vendor|\.cache|\.venv|env|__pycache__)\\'
    Write-Action "Scanning files for '$Pattern' (Depth: $MaxDepth)..."
    $files = Get-ChildItem -Path $Path -Recurse -Depth $MaxDepth -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch $Ignore }
    $results = $files | Select-String -Pattern $Pattern
    if ($results) { 
        $results | ForEach-Object { Write-Host "  $IconArrow $($_.FileName):$($_.LineNumber): $($_.Line.Trim())" -ForegroundColor Gray }
        Write-Success "Found $($results.Count) matches in $($files.Count) files."
    } else { 
        Write-Alert "No matches found in $($files.Count) files scanned." 
    }
}
Set-Alias fxt Select-FileText

function Get-DirectorySize {
    # Calculates the total size of a directory.
    param([string]$Path = ".", [int]$MaxDepth = 5)
    Write-Host "  $IconInfo Arguments: -MaxDepth 10" -ForegroundColor Cyan
    Write-Action "Calculating size for: $Path"
    try {
        $fullPath = (Resolve-Path $Path).Path
        $size = (Get-ChildItem -Path $fullPath -Recurse -Depth $MaxDepth -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        if ($null -eq $size) { $size = 0 }
        $disp = if ($size -ge 1GB) { "{0:N2} GB" -f ($size / 1GB) } elseif ($size -ge 1MB) { "{0:N2} MB" -f ($size / 1MB) } else { "{0:N2} KB" -f ($size / 1KB) }
        Write-Success "Size of '$($fullPath.Split('\')[-1])': $disp"
    } catch { 
        Write-Failure "Calculation failed." 
    }
}
Set-Alias dsize Get-DirectorySize

function Unblock-FolderFiles {
    # Unblocks files in a folder, optionally recursing.
    param([string]$Path = ".", [int]$MaxDepth, [switch]$Recurse)
    Write-Host "  $IconInfo Arguments: <path> | -Recurse | -MaxDepth 2" -ForegroundColor Cyan
    
    $targetPath = if (Test-Path $Path) { (Resolve-Path $Path).Path } else { $Path }
    
    if ($MaxDepth -gt 0) {
        Write-Action "Unblocking files in '$targetPath' (Depth: $MaxDepth)..."
        Get-ChildItem -Path $targetPath -File -Recurse -Depth $MaxDepth | Unblock-File
    } elseif ($Recurse) {
        Write-Action "Unblocking files in '$targetPath' (Full Recursion)..."
        Get-ChildItem -Path $targetPath -File -Recurse | Unblock-File
    } else {
        Write-Action "Unblocking files in '$targetPath' (Current Folder)..."
        Get-ChildItem -Path $targetPath -File | Unblock-File
    }
    Write-Success "All files in scope are now unblocked."
}
Set-Alias unblock Unblock-FolderFiles

function .. {
    # Moves up one directory level.
    Set-Location ..
    Write-Info "Location: $(Get-Location)"
}

function ... {
    # Moves up two directory levels.
    Set-Location ..\..
    Write-Info "Location: $(Get-Location)"
}

# =============================================================================
# >>>  DEVELOPER UTILITIES: GIT WORKFLOW                                   <<<
# =============================================================================

function gst {
    # Git Status shorthand.
    if ($args.Count -eq 0) { 
        Write-Host "  $IconInfo Arguments: -s -b" -ForegroundColor Cyan 
    }
    git status $args
}

function gpl {
    # Git Pull shorthand.
    if ($args.Count -eq 0) { 
        Write-Host "  $IconInfo Arguments: --rebase | --autostash | --ff-only" -ForegroundColor Cyan 
    }
    Write-Action "Pulling from origin..."
    git pull $args
    Write-Success "Git Pull completed."
}

function gdf {
    # Git Diff shorthand.
    if ($args.Count -eq 0) { 
        Write-Host "  $IconInfo Arguments: --staged | --stat" -ForegroundColor Cyan 
    }
    git diff $args
}

function glo {
    # Git Log shorthand.
    if ($args.Count -eq 0) { 
        Write-Host "  $IconInfo Arguments: --oneline --graph --decorate | -n 5 | -p" -ForegroundColor Cyan 
    }
    git log $args
}

function gco {
    # Git Checkout shorthand.
    if ($args.Count -eq 0) { 
        Write-Host "  $IconInfo Arguments: -b <name> (new) | - (previous)" -ForegroundColor Cyan 
    }
    git checkout $args
}


function Sync-GitBranch {
    # Syncs current branch with origin (Add + Commit + Rebase Pull + Push).
    param([Parameter(Mandatory)][string]$Message)
    $Branch = (git branch --show-current)
    if (-not $Branch) { 
        Write-Failure "Current directory is not a Git repository."
        return 
    }
    Write-Action "Auto-syncing '$Branch' to origin..."
    git add .
    git commit -m "$Message"
    git pull origin "$Branch" --rebase
    git push origin "$Branch"
    Write-Success "Branch '$Branch' is now in sync with origin."
}
Set-Alias gup Sync-GitBranch

function Initialize-GitRepo {
    # Initializes a new Git repo, commits all, and pushes to remote.
    param([Parameter(Mandatory)][string]$RepoUrl)
    Write-Action "Initializing and publishing Git repository..."
    git init
    git add .
    git commit -m "Initial commit"
    git branch -M main
    git remote add origin "$RepoUrl"
    git push -u origin main
    Write-Success "Repository initialized and pushed to: $RepoUrl"
}
Set-Alias gnew Initialize-GitRepo

function Copy-GitRepo {
    # Clones a repository and enters its directory.
    param([Parameter(Mandatory)][string]$Url, [Parameter(ValueFromRemainingArguments)][string[]]$GitArgs)
    Write-Host "  $IconInfo Arguments: <folder> | -b <branch> | --depth 1" -ForegroundColor Cyan
    Write-Action "Cloning repository from: $Url"
    git clone $Url $GitArgs
    if ($LASTEXITCODE -ne 0) { return }

    $TargetDir = (($Url -split '/')[-1] -replace '\.git$', '')
    if ($GitArgs) {
        $LastArg = $GitArgs[-1]
        if (Test-Path $LastArg) { $TargetDir = $LastArg }
    }

    if (Test-Path $TargetDir) { 
        Set-Location $TargetDir
        Write-Success "Clone complete. Entered directory: $TargetDir"
        Get-ChildItem 
    }
}
Set-Alias gcl Copy-GitRepo

function Remove-GitRepo {
    # Removes the .git folder from the current directory.
    if (Test-Path .git) { 
        Write-Action "Destroying Git tracking (.git folder)..."
        Remove-Item .git -Recurse -Force
        Write-Success "Git tracking has been removed." 
    } else { 
        Write-Failure "No .git folder found in this directory." 
    }
}
Set-Alias grem Remove-GitRepo

# =============================================================================
# >>>  DEVELOPER UTILITIES: SYSTEM & PROCESS                               <<<
# =============================================================================

function Stop-ProcessByNameOrPort {
    # Stops processes based on their name or the port they are listening on.
    [CmdletBinding(DefaultParameterSetName = 'ByPort')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ByPort', Position = 0)][int]$Port,
        [Parameter(Mandatory = $true, ParameterSetName = 'ByName', Position = 0)][string]$Name
    )
    if ($PSCmdlet.ParameterSetName -eq 'ByPort') {
        Write-Action "Searching for processes on port $Port..."
        $conns = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
        if ($conns) {
            # Extract unique PIDs to avoid trying to kill the same process multiple times
            $conns | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object { 
                try {
                    Stop-Process -Id $_ -Force -ErrorAction Stop
                    Write-Success "Killed PID $_" 
                } catch {
                    Write-Alert "Skipped PID $_ - Process already exited or access denied."
                }
            }
        } else { 
            Write-Alert "No processes found on port $Port." 
        }
    } else {
        Write-Action "Searching for processes matching '$Name'..."
        $procs = Get-Process -Name "*$Name*" -ErrorAction SilentlyContinue
        if ($procs) {
            $procs | ForEach-Object { 
                try {
                    Stop-Process -Id $_.Id -Force -ErrorAction Stop
                    Write-Success "Killed $($_.ProcessName) (PID: $($_.Id))" 
                } catch {
                    Write-Alert "Skipped $($_.ProcessName) (PID: $($_.Id)) - Process already exited or access denied."
                }
            }
        } else { 
            Write-Alert "No processes matching '$Name' were found." 
        }
    }
}
Set-Alias kproc Stop-ProcessByNameOrPort

function Get-PublicIP {
    # Fetches your public IP address and copies it to the clipboard.
    Write-Action "Fetching public IP from ipify.org..."
    try {
        $ip = Invoke-RestMethod -Uri "https://api.ipify.org" -ErrorAction Stop
        $ip | Set-Clipboard
        Write-Success "Public IP: $ip (Successfully copied to clipboard)"
    } catch { 
        Write-Failure "Failed to reach IP service." 
    }
}
Set-Alias myip Get-PublicIP

function Get-NetworkInfo {
    # Retrieves IP and MAC addresses for the local PC and its default gateway.
    Write-Action "Retrieving local and gateway network details..."
    try {
        $config = Get-NetIPConfiguration | Where-Object { $null -ne $_.IPv4DefaultGateway } | Select-Object -First 1
        if (-not $config) {
            Write-Alert "No active network interface with a default gateway found."
            return
        }

        $gwIp = $config.IPv4DefaultGateway.NextHop
        $localIp = $config.IPv4Address.IPAddress
        $adapter = Get-NetAdapter -InterfaceIndex $config.InterfaceIndex
        $localMac = $adapter.MacAddress

        $gwNeighbor = Get-NetNeighbor -IPAddress $gwIp -ErrorAction SilentlyContinue | Select-Object -First 1
        $gwMac = if ($gwNeighbor) { $gwNeighbor.LinkLayerAddress } else { "Not Found in ARP Cache" }

        # Styled output
        $c = [char]27
        $accentColor = "$c[90m"
        $reset = "$c[0m"

        Write-Host ""
        Write-Host "  $IconInfo NETWORK INTERFACE: " -NoNewline; Write-Host $config.InterfaceAlias -ForegroundColor Yellow
        Write-Host "  $accentColor$($LineChar * 50)$reset"
        Write-Host "  $IconArrow Local IP:    " -NoNewline; Write-Host $localIp -ForegroundColor Cyan
        Write-Host "  $IconArrow Local MAC:   " -NoNewline; Write-Host $localMac -ForegroundColor Gray
        Write-Host "  $IconArrow Gateway IP:  " -NoNewline; Write-Host $gwIp -ForegroundColor Cyan
        Write-Host "  $IconArrow Gateway MAC: " -NoNewline; Write-Host $gwMac -ForegroundColor Gray
        Write-Host "  $accentColor$($LineChar * 50)$reset"
        Write-Host ""

        Write-Success "Network details retrieved."
    }
    catch {
        Write-Failure "Failed to retrieve network info: $($_.Exception.Message)"
    }
}
Set-Alias mac Get-NetworkInfo

function Start-FileShare {
    # Starts a modern web server for file sharing in the current directory.
    param([int]$Port = 5000)
    
    Write-Action "Initializing Local File Server..."
    
    # Check for Dufs engine
    if (-not (Get-Command dufs -ErrorAction SilentlyContinue)) {
        Write-Failure "File Server Engine (Dufs) is not installed. Fix: winget install sigoden.Dufs"
        return
    }

    try {
        # Get LAN IP for sharing
        $config = Get-NetIPConfiguration | Where-Object { $null -ne $_.IPv4DefaultGateway } | Select-Object -First 1
        $ip = if ($config) { $config.IPv4Address.IPAddress } else { "localhost" }
        $url = "http://$($ip):$Port"

        $c = [char]27
        $accentColor = "$c[90m"
        $reset = "$c[0m"

        Write-Host ""
        Write-Host "  $IconInfo SHARING DIRECTORY" -ForegroundColor Cyan
        Write-Host "  $accentColor$($LineChar * 50)$reset"
        Write-Host "  $IconArrow URL: " -NoNewline; Write-Host $url -ForegroundColor Yellow
        Write-Host "  $IconArrow Path: $(Get-Location)"
        Write-Host "  $IconArrow Mode: Full Access (Upload/Download/Search/Delete)"
        Write-Host "  $accentColor$($LineChar * 50)$reset"
        Write-Host "  [ Press Ctrl+C to stop sharing ]" -ForegroundColor Gray
        Write-Host ""

        # Start Dufs with allow-all permissions
        dufs . --port $Port --allow-all
    }
    catch {
        Write-Failure "An unexpected error occurred: $($_.Exception.Message)"
    }
}
Set-Alias share Start-FileShare

function Get-CommandSource {
    # Finds the source (path or module) of a command.
    param([Parameter(Mandatory)][string]$Name, [switch]$All)
    Write-Host "  $IconInfo Arguments: -All" -ForegroundColor Cyan
    $cmd = Get-Command $Name -All:$All -ErrorAction SilentlyContinue
    if ($cmd) { 
        Write-Info "Source for '$Name' $IconArrow $($cmd.Source)" 
    } else { 
        Write-Failure "Command '$Name' not found." 
    }
}
Set-Alias which Get-CommandSource

function Clear-TerminalHistory {
    # Clears the terminal history both in session and in the history file.
    Write-Action "Purging terminal history..."
    [Microsoft.PowerShell.PSConsoleReadLine]::ClearHistory()
    $historyPath = (Get-PSReadLineOption).HistorySavePath
    if (Test-Path $historyPath) { 
        Remove-Item $historyPath -Force 
    }
    Clear-History
    Write-Success "All command history has been cleared."
}
Set-Alias clh Clear-TerminalHistory

function Update-ProfileDependencies {
    # Updates the core dependencies used by this profile.
    Write-Action "Synchronizing Profile Dependencies..."

    # Check for Admin rights
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Alert "Running without Administrator privileges. Binary updates may fail."
        Write-Host "    $IconInfo Recommendation: Run terminal as Admin for full sync." -ForegroundColor Gray
    }

    # 1. PowerShell Modules
    $modules = @("PSReadLine", "Terminal-Icons")
    foreach ($m in $modules) {
        Write-Action "Syncing Module: $m..."
        try {
            if ($m -eq "PSReadLine" -and (Get-Module -Name PSReadLine -ErrorAction SilentlyContinue)) {
                Write-Info "PSReadLine is currently in use. Update skipped."
                Write-Host "    $IconInfo Tip: Run 'pwsh -NoProfile' then 'Update-Module PSReadLine' to update." -ForegroundColor Gray
                continue
            }
            Update-Module -Name $m -ErrorAction Stop -Scope CurrentUser
            Write-Success "$m is synchronized."
        } catch {
            Write-Alert "Sync failed for $m. Manual update may be required."
        }
    }

    # 2. Binary Tools (Winget)
    $tools = @("sigoden.Dufs", "JanDeDobbeleer.OhMyPosh")
    foreach ($t in $tools) {
        Write-Action "Syncing Binary: $t..."
        try {
            & winget upgrade --id $t --silent --accept-package-agreements --accept-source-agreements | Out-Null
            
            # Known Success/No-Update Exit Codes:
            # 0           = Success
            # -1978335186 = 0x8A15002E (No applicable upgrade found)
            # -1978335189 = 0x8A15002B (Update not applicable)
            $successCodes = @(0, -1978335186, -1978335189)
            
            if ($successCodes -contains $LASTEXITCODE) {
                Write-Success "$t is synchronized."
            } else {
                Write-Alert "Check $t (Exit Code: $LASTEXITCODE)."
            }
        } catch {
            Write-Failure "Failed to check $t."
        }
    }
    
    Write-Success "All profile dependencies processed."
}
Set-Alias sync Update-ProfileDependencies

function Update-SystemPackages {
    # Checks for and installs updates via Winget with an interactive menu.
    Write-Action "Syncing Winget catalogs..."
    winget source update | Out-Null
    
    Write-Info "Checking for application updates..."
    $oldProg = $env:WINGET_DISABLE_PROGRESS
    $env:WINGET_DISABLE_PROGRESS = "1"
    $output = winget upgrade
    $env:WINGET_DISABLE_PROGRESS = $oldProg

    if (-not $output -or $output -match "No installed package found") { 
        Write-Success "All systems up to date."
        return 
    }

    $headerLine = $output | Where-Object { $_ -match "^Name\s+Id\s+Version" } | Select-Object -First 1
    $separatorLine = $output | Where-Object { $_ -match "^-+$" } | Select-Object -First 1
    
    if (-not $headerLine -or -not $separatorLine) { 
        Write-Alert "Parsing failed or no updates found."
        return 
    }

    $idIdx = $headerLine.IndexOf("Id")
    $verIdx = $headerLine.IndexOf("Version")
    $availIdx = $headerLine.IndexOf("Available")
    $sepIndex = [array]::IndexOf($output, $separatorLine)
    
    $packageLines = $output[($sepIndex + 1)..($output.Count - 1)] | Where-Object { $_.Trim() -ne "" -and $_ -notmatch "^\d+ upgrades" }

    $packages = @()
    $counter = 1
    foreach ($line in $packageLines) {
        if ($line.Length -gt $idIdx) {
            $name = $line.Substring(0, $idIdx).Trim()
            $id = $line.Substring($idIdx, $verIdx - $idIdx).Trim()
            $vLen = if ($line.Length -lt $availIdx) { $line.Length - $verIdx } else { $availIdx - $verIdx }
            $ver = $line.Substring($verIdx, $vLen).Trim()
            $avail = if ($line.Length -gt $availIdx) { ($line.Substring($availIdx).Trim() -split '\s+')[0] } else { "" }
            
            if ($id) { 
                $packages += [PSCustomObject]@{ 
                    Number    = $counter
                    Name      = $name
                    Id        = $id
                    Version   = $ver
                    Available = $avail 
                }
                $counter++ 
            }
        }
    }

    Write-Host "`n  $IconArrow Available Updates:" -ForegroundColor Cyan
    foreach ($pkg in $packages) {
        $disp = if ($pkg.Name.Length -gt 35) { $pkg.Name.Substring(0, 32) + "..." } else { $pkg.Name }
        Write-Host ("  [{0,-2}] {1,-35} | {2,-15} -> {3}" -f $pkg.Number, $disp, $pkg.Version, $pkg.Available)
    }

    Write-Host "`n  [a] Update All | [a -2 -3] All Except | [1 2] Select | [q] Quit" -ForegroundColor Cyan
    $choice = (Read-Host "  Selection").Trim().ToLower()
    
    if (-not $choice -or $choice -eq 'q') { 
        Write-Alert "Operation canceled."
        return 
    }

    $toUpdate = @()
    if ($choice -match '^a\s*-') { 
        $excl = [regex]::Matches($choice, '-\d+') | ForEach-Object { [int]($_.Value.Replace('-', '')) }
        $toUpdate = $packages | Where-Object { $_.Number -notin $excl } | Select-Object -ExpandProperty Id 
    } elseif ($choice -eq 'a') { 
        Write-Action "Updating all items via Winget..."
        winget upgrade --all
        return 
    } else { 
        $incl = [regex]::Matches($choice, '\d+') | ForEach-Object { [int]$_.Value }
        $toUpdate = $packages | Where-Object { $_.Number -in $incl } | Select-Object -ExpandProperty Id 
    }

    foreach ($id in $toUpdate) { 
        Write-Action "Updating: $id..."
        winget upgrade --id $id --exact 
    }
    Write-Success "Update process finished."
}
Set-Alias update Update-SystemPackages

# =============================================================================
# >>>  PROFILE MANAGEMENT & HELP SYSTEM                                    <<<
# =============================================================================

function Edit-Profile {
    # Opens the PowerShell profile in Notepad for editing.
    Write-Action "Opening Profile for editing..."
    notepad $PROFILE
}
Set-Alias pro Edit-Profile

function Update-Profile { 
    # Reloads the PowerShell profile.
    if (Test-Path $Global:ProfileSourcePath) {
        . $Global:ProfileSourcePath
    } else {
        . $PROFILE
    }
    Write-Success "Profile reloaded successfully."
}
Set-Alias ref Update-Profile

function Show-ProfileHelp {
    # Displays an interactive command cheat sheet.
    $c = [char]27
    $headerColor = "$c[1;35m"
    $sectionColor = "$c[1;36m"
    $accentColor = "$c[90m"
    $reset = "$c[0m"

    $helpData = @(
        @{ 
            Title = "󰊢 GIT WORKFLOW"
            Items = @(
                @{ Cmd = "gup <msg>"; Desc = "Sync (Add+Commit+Pull+Push)" }
                @{ Cmd = "gnew <url>"; Desc = "Init + Remote Push" }
                @{ Cmd = "gcl <url>"; Desc = "Clone + Enter" }
                @{ Cmd = "gst / gdf / glo"; Desc = "Status / Diff / Log" }
                @{ Cmd = "gco"; Desc = "Checkout" }
            )
        }
        @{ 
            Title = "󰉋 NAVIGATION & FILES"
            Items = @(
                @{ Cmd = "mkcd <path>"; Desc = "New Dir + Enter" }
                @{ Cmd = "fxt <query>"; Desc = "Search Content (Depth 3)" }
                @{ Cmd = "dsize"; Desc = "Folder Size (Depth 5)" }
                @{ Cmd = "unblock"; Desc = "Recursive Unblock" }
                @{ Cmd = ".. / ..."; Desc = "Level Up" }
            )
        }
        @{ 
            Title = "󰈸 SYSTEM"
            Items = @(
                @{ Cmd = "update"; Desc = "Winget Checks" }
                @{ Cmd = "sync"; Desc = "Update Profile Deps" }
                @{ Cmd = "kproc <arg>"; Desc = "Kill by Port or Name" }
                @{ Cmd = "myip"; Desc = "Public IP to Clipboard" }
                @{ Cmd = "mac"; Desc = "Local & Gateway IP/MAC" }
                @{ Cmd = "share"; Desc = "Start GUI File Server" }
                @{ Cmd = "pro / ref"; Desc = "Edit / Reload Profile" }
            )
        }
    )

    Write-Host "`n  $headerColor$IconInfo COMMAND CHEAT SHEET$reset"
    Write-Host "  $accentColor$( $LineChar * 50 )$reset"

    foreach ($section in $helpData) {
        Write-Host "  $sectionColor$($section.Title)$reset"
        foreach ($item in $section.Items) {
            Write-Host ("    {0,-15} $accentColor$IconArrow$reset {1}" -f $item.Cmd, $item.Desc)
        }
        Write-Host ""
    }

    Write-Host "  $accentColor$( $LineChar * 50 )$reset`n"
}
Set-Alias menu Show-ProfileHelp
