# Advanced PowerShell Profile Configuration
# Standardized developer environment with git enhancements, system utilities,
# and a custom interface system.

# =============================================================================
# >>>  CORE ENVIRONMENT & PERFORMANCE                                      <<<
# =============================================================================

# Force UTF-8 encoding for high-fidelity icon rendering
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Advanced Performance Flags
$env:POSH_GIT_STATUS_ASYNC = 1   # Don't hang on large repos
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

function Write-Error {
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
    } 
    else { 
        New-Item -ItemType File -Path $Path -Force | Out-Null
        Write-Success "New file created: $Path" 
    }
}
Set-Alias touch Set-TouchFile

function Select-FileText {
    # Searches for a text pattern within files, excluding common development folders.
    param([string]$Pattern, [string]$Path = ".", [int]$MaxDepth = 3)
    $Ignore = '\\(\.git|node_modules|\.next|bin|obj|dist|build|vendor|\.cache|\.venv|env|__pycache__)\\'
    Write-Action "Scanning files for '$Pattern' (Depth: $MaxDepth)..."
    $files = Get-ChildItem -Path $Path -Recurse -Depth $MaxDepth -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch $Ignore }
    $results = $files | Select-String -Pattern $Pattern
    if ($results) { 
        $results | ForEach-Object { Write-Host "  $IconArrow $($_.FileName):$($_.LineNumber): $($_.Line.Trim())" -ForegroundColor Gray }
        Write-Success "Found $($results.Count) matches in $($files.Count) files."
    }
    else { 
        Write-Alert "No matches found in $($files.Count) files scanned." 
    }
}
Set-Alias fxt Select-FileText

function Get-DirectorySize {
    # Calculates the total size of a directory.
    param([string]$Path = ".", [int]$MaxDepth = 5)
    Write-Action "Calculating size for: $Path"
    try {
        $fullPath = (Resolve-Path $Path).Path
        $size = (Get-ChildItem -Path $fullPath -Recurse -Depth $MaxDepth -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        if ($null -eq $size) { $size = 0 }
        $disp = if ($size -ge 1GB) { "{0:N2} GB" -f ($size / 1GB) } elseif ($size -ge 1MB) { "{0:N2} MB" -f ($size / 1MB) } else { "{0:N2} KB" -f ($size / 1KB) }
        Write-Success "Size of '$($fullPath.Split('\')[-1])': $disp"
    }
    catch { Write-Error "Calculation failed." }
}
Set-Alias dsize Get-DirectorySize

function Unblock-FolderFiles {
    # Unblocks files in the current folder, optionally recursing.
    param([switch]$Recurse)
    Write-Action "Unblocking files (Recurse: $Recurse)..."
    if ($Recurse) { Get-ChildItem -File -Recurse | Unblock-File } else { Get-ChildItem -File | Unblock-File }
    Write-Success "All files in scope are now unblocked."
}
Set-Alias unblock Unblock-FolderFiles

function New-SymbolicLink {
    # Creates a symbolic link for a file or directory.
    param([Parameter(Mandatory)][string]$Target, [Parameter(Mandatory)][string]$Name)
    Write-Action "Creating symbolic link..."
    try {
        $targetPath = (Resolve-Path $Target).Path
        New-Item -ItemType SymbolicLink -Path $Name -Target $targetPath -Force | Out-Null
        Write-Success "Link established: $Name $IconArrow $targetPath"
    }
    catch { Write-Error "Link creation failed (Check Admin rights)." }
}
Set-Alias ln New-SymbolicLink

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

function gs {
    # Git Status shorthand.
    git status $args
}

function gpl {
    # Git Pull with feedback.
    Write-Action "Pulling from origin..."
    git pull $args
    Write-Success "Git Pull completed."
}

function gd {
    # Git Diff shorthand.
    git diff $args
}

if (Get-Alias gl -ErrorAction SilentlyContinue) { Remove-Item Alias:gl -Force }
function gl {
    # Git Log with graph and decoration.
    git log --oneline --graph --decorate --all $args
}

function Sync-GitBranch {
    # Syncs current branch with origin (Add + Commit + Rebase Pull + Push).
    param([Parameter(Mandatory)][string]$Message)
    $Branch = (git branch --show-current)
    if (-not $Branch) { 
        Write-Error "Current directory is not a Git repository."
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
    Write-Action "Performing Platinum Git Init..."
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
    param([string]$Url, [Parameter(ValueFromRemainingArguments)][string[]]$GitArgs)
    Write-Action "Cloning repository from: $Url"
    git clone $Url $GitArgs
    if ($LASTEXITCODE -ne 0) { return }

    # Identify the target directory (either custom or default from URL)
    $TargetDir = (($Url -split '/')[-1] -replace '\.git$', '')
    if ($GitArgs) {
        $LastArg = $GitArgs[-1]
        # If the last argument matches an existing directory, we assume it's the target
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
    } 
    else { 
        Write-Error "No .git folder found in this directory." 
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
            $conns | ForEach-Object { 
                Stop-Process -Id $_.OwningProcess -Force
                Write-Success "Killed PID $($_.OwningProcess)" 
            }
        }
        else { 
            Write-Alert "No processes found on port $Port." 
        }
    }
    else {
        Write-Action "Searching for processes matching '$Name'..."
        $procs = Get-Process -Name "*$Name*" -ErrorAction SilentlyContinue
        if ($procs) {
            $procs | ForEach-Object { 
                Stop-Process -Id $_.Id -Force
                Write-Success "Killed $($_.ProcessName) (PID: $($_.Id))" 
            }
        }
        else { 
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
    }
    catch { 
        Write-Error "Failed to reach IP service." 
    }
}
Set-Alias myip Get-PublicIP

function Get-CommandSource {
    # Finds the source (path or module) of a command.
    param([string]$Name)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) { 
        Write-Info "Source for '$Name' $IconArrow $($cmd.Source)" 
    }
    else { 
        Write-Error "Command '$Name' not found." 
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
    
    $packageLines = $output[($sepIndex + 1)..($output.Count - 1)] | 
    Where-Object { $_.Trim() -ne "" -and $_ -notmatch "^\d+ upgrades" }

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

    Write-Host "`n  [a] Update All | [1 2] Select | [q] Quit" -ForegroundColor Cyan
    $choice = (Read-Host "  Selection").Trim().ToLower()
    
    if (-not $choice -or $choice -eq 'q') { 
        Write-Alert "Operation canceled."
        return 
    }

    $toUpdate = @()
    if ($choice -match '^a\s*-') { 
        $excl = [regex]::Matches($choice, '-\d+') | ForEach-Object { [int]($_.Value.Replace('-', '')) }
        $toUpdate = $packages | Where-Object { $_.Number -notin $excl } | Select-Object -ExpandProperty Id 
    }
    elseif ($choice -eq 'a') { 
        Write-Action "Updating all items via Winget..."
        winget upgrade --all
        return 
    }
    else { 
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

function Invoke-TerminalReset {
    # Sends escape codes to reset terminal mouse/focus tracking.
    # Includes: ?1000l (Click), ?1002l (Drag), ?1003l (Motion), ?1004l (Focus), ?1006l (SGR Encoding)
    Write-Host -NoNewline "$([char]27)[?1000l$([char]27)[?1002l$([char]27)[?1003l$([char]27)[?1004l$([char]27)[?1006l"
}

function Update-Profile { 
    # Reloads the PowerShell profile.
    Invoke-TerminalReset
    . $PROFILE
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
                @{ Cmd = "gs / gd / gl"; Desc = "Status / Diff / Log" }
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
                @{ Cmd = "kproc <arg>"; Desc = "Kill by Port or Name" }
                @{ Cmd = "myip"; Desc = "Public IP to Clipboard" }
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

if (Get-Command 'prompt' -ErrorAction SilentlyContinue) {
    $script:oldP = $function:prompt
    function prompt {
        # Custom prompt wrapper to ensure terminal reset on every command.
        Invoke-TerminalReset
        if ($script:oldP) { 
            & $script:oldP 
        }
        else { 
            "PS $($ExecutionContext.SessionState.Path.CurrentLocation)> " 
        }
    }
}

Invoke-TerminalReset
