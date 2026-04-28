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
$env:POSH_THEME_CACHING = 1
$env:POSH_THEMES_PATH = Join-Path $env:LOCALAPPDATA "Programs\oh-my-posh\themes"

# =============================================================================
# >>>  INTERFACE & FEEDBACK SYSTEM                                         <<<
# =============================================================================

$IconOk = [string][char]::ConvertFromUtf32(0xF012C) # 󰄬
$IconInfo = [string][char]::ConvertFromUtf32(0xF02FD) # 󰋽
$IconWarn = [string][char]::ConvertFromUtf32(0xF11CE) # 󱇎
$IconFail = [string][char]::ConvertFromUtf32(0xF0156) # 󰅖
$IconBusy = [string][char]::ConvertFromUtf32(0xF1454) # 󱑔
$IconArrow = [string][char]::ConvertFromUtf32(0x279C)  # ➜
$LineChar = [string][char]0x2501                     # ━

function Write-Success { param([string]$msg) Write-Host "  [ " -NoNewline; Write-Host "$IconOk OK" -ForegroundColor Green -NoNewline; Write-Host " ] $msg" }
function Write-Info { param([string]$msg) Write-Host "  [ " -NoNewline; Write-Host "$IconInfo INFO" -ForegroundColor Cyan -NoNewline; Write-Host " ] $msg" }
function Write-Alert { param([string]$msg) Write-Host "  [ " -NoNewline; Write-Host "$IconWarn WARN" -ForegroundColor Yellow -NoNewline; Write-Host " ] $msg" }
function Write-Failure { param([string]$msg) Write-Host "  [ " -NoNewline; Write-Host "$IconFail FAIL" -ForegroundColor Red -NoNewline; Write-Host " ] $msg" }
function Write-Action { param([string]$msg) Write-Host "  [ " -NoNewline; Write-Host "$IconBusy BUSY" -ForegroundColor Magenta -NoNewline; Write-Host " ] $msg" }

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
# >>>  NAVIGATION & FILESYSTEM                                              <<<
# =============================================================================

function Initialize-Directory {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$Path)
    if ($PSCmdlet.ShouldProcess($Path, "Create directory and change location")) {
        Write-Action "Initializing directory: $Path"
        try {
            $item = New-Item -ItemType Directory -Path $Path -Force -ErrorAction Stop
            Set-Location $item.FullName
            Write-Success "Location: $(Get-Location)"
        }
        catch {
            Write-Failure "Failed to initialize directory: $($_.Exception.Message)"
        }
    }
}
Set-Alias mdc Initialize-Directory

function Set-TouchFile {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$Path)
    if ($PSCmdlet.ShouldProcess($Path, "Touch file")) {
        if (Test-Path $Path) { 
            (Get-Item $Path).LastWriteTime = Get-Date
            Write-Info "Touched: $Path" 
        }
        else { 
            New-Item -ItemType File -Path $Path -Force | Out-Null
            Write-Success "Created: $Path" 
        }
    }
}
Set-Alias touch Set-TouchFile

function Select-FileText {
    param(
        [Parameter(Mandatory = $true, Position = 0)][string]$Pattern,
        [Parameter(Mandatory = $false, Position = 1)][string]$SearchPath = ".",
        [Parameter(Mandatory = $false)][Alias("d")][int]$MaxDepth
    )
    # Ignore common junk and binary extensions
    $IgnoreDirs = ".git", "node_modules", ".next", "bin", "obj", "dist", "build", "vendor", ".cache", ".venv", "env", "__pycache__"
    $IgnoreExts = "*.exe", "*.dll", "*.pdb", "*.bin", "*.png", "*.jpg", "*.jpeg", "*.gif", "*.ico", "*.zip", "*.7z", "*.rar"
    
    $c = [char]27; $cyan = "$c[1;36m"; $magenta = "$c[1;35m"; $gray = "$c[90m"; $reset = "$c[0m"
    $FileIcon = [char]::ConvertFromUtf32(0xF012F) # 󰈙

    $absPath = if ($SearchPath -eq ".") { $PWD.Path } else { (Resolve-Path $SearchPath).Path }
    Write-Action "Searching for '$Pattern' in: $absPath"

    $ExtRegex = ($IgnoreExts -replace '\*', '.*' -join '|')
    $DirRegex = "\\($($IgnoreDirs -join '|'))\\"
    $results = Get-ChildItem -Path $absPath -Recurse -File -ErrorAction SilentlyContinue | 
               Where-Object { 
                   $_.Name -notmatch $ExtRegex -and 
                   $_.FullName -notmatch $DirRegex 
               } |
               Select-String -Pattern $Pattern
    
    if ($results) {
        Write-Host ""
        $grouped = $results | Group-Object Filename
        $grouped | ForEach-Object {
            Write-Host "  $FileIcon $cyan$($_.Name)$reset"
            $_.Group | ForEach-Object {
                $content = $_.Line.Trim()
                if ($content.Length -gt 100) { $content = $content.Substring(0, 97) + "..." }
                Write-Host "    $magenta$($_.LineNumber)$reset $IconArrow $gray$content$reset"
            }
        }
        $matchCount = $results.Count
        $fileCount = $grouped.Count
        $matchText = if ($matchCount -eq 1) { "match" } else { "matches" }
        $fileText = if ($fileCount -eq 1) { "file" } else { "files" }
        Write-Success "Found $cyan$matchCount$reset $matchText across $cyan$fileCount$reset $fileText."
    } else { Write-Alert "No matches found in: $absPath" }
}
Set-Alias sf Select-FileText

function Get-DirectorySize {
    param(
        [Parameter(Mandatory = $false, Position = 0)][string]$SearchPath = ".",
        [Parameter(Mandatory = $false)][Alias("d")][int]$MaxDepth
    )
    Write-Action "Calculating size: $SearchPath"
    try {
        $fullPath = (Resolve-Path $SearchPath).Path
        $params = @{
            Path        = $fullPath
            Recurse     = $true
            File        = $true
            ErrorAction = "SilentlyContinue"
        }
        if ($MaxDepth -gt 0) { $params["Depth"] = $MaxDepth }
        
        $size = (Get-ChildItem @params | Measure-Object -Property Length -Sum).Sum
        if ($null -eq $size) { $size = 0 }
        $disp = if ($size -ge 1GB) { "{0:N2} GB" -f ($size / 1GB) } elseif ($size -ge 1MB) { "{0:N2} MB" -f ($size / 1MB) } else { "{0:N2} KB" -f ($size / 1KB) }
        Write-Success "Size: $disp"
    }
    catch { Write-Failure "Size check failed." }
}
Set-Alias ds Get-DirectorySize

function Unblock-FolderFile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Path = ".",
        [Alias("d")][int]$MaxDepth,
        [Alias("r")][switch]$Recurse
    )
    $targetPath = if (Test-Path $Path) { (Resolve-Path $Path).Path } else { $Path }
    if ($PSCmdlet.ShouldProcess($targetPath, "Unblock files")) {
        Write-Action "Unblocking files in '$targetPath'..."
        if ($MaxDepth -gt 0) { Get-ChildItem -Path $targetPath -File -Recurse -Depth $MaxDepth | Unblock-File }
        elseif ($Recurse) { Get-ChildItem -Path $targetPath -File -Recurse | Unblock-File }
        else { Get-ChildItem -Path $targetPath -File | Unblock-File }
        Write-Success "Unblock complete."
    }
}
Set-Alias unblock Unblock-FolderFile

function .. { Set-Location ..; Write-Info "Location: $(Get-Location)" }
function ... { Set-Location ..\..; Write-Info "Location: $(Get-Location)" }

# =============================================================================
# >>>  GIT WORKFLOW                                                         <<<
# =============================================================================

function gst { git status $args }
function gpl { Write-Action "Pulling..."; git pull $args; Write-Success "Done." }
function gdf { git diff $args }
function glo { git log --oneline --graph --decorate -n 10 $args }
function gco { git checkout $args }

function Sync-GitBranch {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$Message)
    $Branch = (git branch --show-current)
    if (-not $Branch) { Write-Failure "Not a Git repo."; return }
    if ($PSCmdlet.ShouldProcess($Branch, "Sync branch (Add, Commit, Pull, Push)")) {
        Write-Action "Syncing '$Branch'..."
        git add .
        git commit -m "$Message"
        git pull origin "$Branch" --rebase
        git push origin "$Branch"
        Write-Success "Sync complete."
    }
}
Set-Alias gup Sync-GitBranch

function Initialize-GitRepo {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$RepoUrl)
    if ($PSCmdlet.ShouldProcess($RepoUrl, "Initialize git repo and publish")) {
        Write-Action "Initializing repo..."
        git init; git add .; git commit -m "Initial commit"; git branch -M main
        git remote add origin "$RepoUrl"; git push -u origin main
        Write-Success "Published to: $RepoUrl"
    }
}
Set-Alias gnew Initialize-GitRepo

function Copy-GitRepo {
    param([Parameter(Mandatory)][string]$Url, [Parameter(ValueFromRemainingArguments)][string[]]$GitArgs)
    Write-Action "Cloning: $Url"
    git clone $Url $GitArgs
    if ($LASTEXITCODE -ne 0) { return }
    $TargetDir = (($Url -split '/')[-1] -replace '\.git$', '')
    if ($GitArgs -and (Test-Path $GitArgs[-1])) { $TargetDir = $GitArgs[-1] }
    if (Test-Path $TargetDir) { Set-Location $TargetDir; Write-Success "Entered: $TargetDir" }
}
Set-Alias gcl Copy-GitRepo

function Remove-GitRepo {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    if (Test-Path .git) { 
        if ($PSCmdlet.ShouldProcess(".git", "Remove git tracking")) {
            Remove-Item .git -Recurse -Force; Write-Success "Git tracking removed." 
        }
    }
    else { Write-Failure "No .git folder found." }
}
Set-Alias grem Remove-GitRepo

# =============================================================================
# >>>  SYSTEM & PROCESS                                                     <<<
# =============================================================================

function Stop-ProcessByNameOrPort {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)][object]$Identifier
    )
    
    $isPort = $Identifier -match '^\d+$'
    $targetName = if ($isPort) { "Port $Identifier" } else { "Process matching '$Identifier'" }

    if ($PSCmdlet.ShouldProcess($targetName, "Stop Process")) {
        if ($isPort) {
            Write-Action "Killing port $Identifier..."
            $conns = Get-NetTCPConnection -LocalPort $Identifier -ErrorAction SilentlyContinue
            if ($conns) {
                $conns | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object { 
                    try { Stop-Process -Id $_ -Force -ErrorAction Stop; Write-Success "Killed PID $_" }
                    catch { Write-Alert "Access denied for PID $_" }
                }
            } else { Write-Alert "Port $Identifier is free." }
        } else {
            Write-Action "Killing processes matching '$Identifier'..."
            $procs = Get-Process -Name "*$Identifier*" -ErrorAction SilentlyContinue
            if ($procs) {
                $procs | ForEach-Object { 
                    try { Stop-Process -Id $_.Id -Force -ErrorAction Stop; Write-Success "Killed $($_.ProcessName)" }
                    catch { Write-Alert "Access denied for $($_.ProcessName)" }
                }
            } else { Write-Alert "No processes found matching '$Identifier'." }
        }
    }
}
Set-Alias kp Stop-ProcessByNameOrPort

function Get-CommandSource {
    param(
        [Parameter(Mandatory, Position = 0)][Alias("n")][string]$Name,
        [Alias("a")][switch]$All
    )
    $cmd = Get-Command $Name -All:$All -ErrorAction SilentlyContinue
    if ($cmd) { Write-Info "Source: $($cmd.Source)" }
    else { Write-Failure "Not found." }
}
Set-Alias wh Get-CommandSource

function Clear-TerminalHistory {
    Write-Action "Purging history..."
    [Microsoft.PowerShell.PSConsoleReadLine]::ClearHistory()
    $historyPath = (Get-PSReadLineOption).HistorySavePath
    if (Test-Path $historyPath) { Remove-Item $historyPath -Force }
    Clear-History
    Write-Success "History cleared."
}
Set-Alias clh Clear-TerminalHistory

function Update-SystemPackage {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Failure "Winget not found on this system."
        return
    }

    Write-Action "Checking for updates..."
    $output = winget upgrade | Out-String
    if ($output -match "No installed package found") { Write-Success "System is up to date."; return }
    if ($output -match "No applicable update found") { Write-Success "No updates available."; return }

    $lines = $output -split "`r?`n"
    $startLine = 0
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "Name\s+Id\s+Version\s+Available") {
            $startLine = $i + 2 
            break
        }
    }

    $packages = @()
    $counter = 1
    $regex = "(?<Name>.{2,})\s+(?<Id>[^\s]+)\s+(?<Ver>[^\s]+)\s+(?<Avail>[^\s]+)\s+(?<Source>[^\s]+)"
    
    for ($i = $startLine; $i -lt $lines.Count; $i++) {
        $line = $lines[$i].Trim()
        if (-not $line) { continue }
        if ($line -match $regex) {
            $packages += [PSCustomObject]@{
                Num    = $counter++
                Name   = $Matches['Name'].Trim()
                Id     = $Matches['Id'].Trim()
                Ver    = $Matches['Ver'].Trim()
                Avail  = $Matches['Avail'].Trim()
                Source = $Matches['Source'].Trim()
            }
        }
    }

    if (-not $packages) { Write-Alert "No updates found or parsing failed."; return }

    Write-Host "`n  $IconArrow Available Updates:" -ForegroundColor Cyan
    Write-Host "  $gray#   Package Name                   Current         Available       Source$reset"
    Write-Host "  $gray$($LineChar * 80)$reset"

    foreach ($pkg in $packages) {
        $c = [char]27
        $nameDisp = if ($pkg.Name.Length -gt 30) { $pkg.Name.Substring(0, 27) + "..." } else { $pkg.Name }
        $source = "$c[92m$($pkg.Source)$c[0m"
        
        $v1 = $pkg.Ver -split '\.'
        $v2 = $pkg.Avail -split '\.'
        $highlightParts = @()
        $foundDiff = $false
        for ($j = 0; $j -lt $v2.Count; $j++) {
            $part = $v2[$j]
            if (-not $foundDiff -and $j -lt $v1.Count -and $v1[$j] -ne $part) {
                $highlightParts += "$c[92m$part$c[0m"
                $foundDiff = $true
            }
            elseif ($foundDiff -or $j -ge $v1.Count) {
                $highlightParts += "$c[92m$part$c[0m"
            }
            else {
                $highlightParts += $part
            }
        }
        $highlighted = $highlightParts -join "."

        $availPadding = 16 - $pkg.Avail.Length
        if ($availPadding -lt 0) { $availPadding = 0 }
        $availSpace = " " * $availPadding

        Write-Host ("  [{0}] {1,-30} {2,-15} " -f $pkg.Num, $nameDisp, $pkg.Ver) -NoNewline
        Write-Host "$highlighted$availSpace$source"
    }

    Write-Host "`n  [a] All | [1 2] Select | [q] Quit" -ForegroundColor Cyan
    $choice = (Read-Host "  Selection").Trim().ToLower()
    if ($choice -eq 'q' -or -not $choice) { return }

    $toUpdate = @()
    if ($choice -eq 'a') { winget upgrade --all; return }
    else { 
        $incl = [regex]::Matches($choice, '\d+') | ForEach-Object { [int]$_.Value }
        $toUpdate = $packages | Where-Object { $_.Num -in $incl } | Select-Object -ExpandProperty Id 
    }

    foreach ($id in $toUpdate) { Write-Action "Updating: $id..."; winget upgrade --id $id --exact }
    Write-Success "Update process finished."
}
Set-Alias update Update-SystemPackage

function Update-ProfileDependency {
    Write-Action "Syncing Profile Dependencies..."
    $modules = @("PSReadLine", "Terminal-Icons")
    foreach ($m in $modules) {
        try { Update-Module -Name $m -Scope CurrentUser -ErrorAction SilentlyContinue; Write-Success "$m synced." }
        catch { Write-Alert "Skipped $m." }
    }
    $tools = @("sigoden.Dufs", "JanDeDobbeleer.OhMyPosh")
    foreach ($t in $tools) { winget upgrade --id $t --silent --accept-package-agreements | Out-Null; Write-Success "$t synced." }
}
Set-Alias sync Update-ProfileDependency

# =============================================================================
# >>>  NETWORK UTILITIES                                                   <<<
# =============================================================================

function Get-PublicIP {
    Write-Action "Fetching Public IP..."
    try {
        $ip = Invoke-RestMethod -Uri "https://api.ipify.org" -ErrorAction Stop
        $ip | Set-Clipboard
        Write-Success "Public IP: $ip (Copied)"
    }
    catch { Write-Failure "Service unreachable." }
}
Set-Alias ip Get-PublicIP

function Get-NetworkInfo {
    Write-Action "Retrieving local network details..."
    $config = Get-NetIPConfiguration | Where-Object { $null -ne $_.IPv4DefaultGateway } | Select-Object -First 1
    if ($config) {
        $gwNeighbor = Get-NetNeighbor -IPAddress $config.IPv4DefaultGateway.NextHop -ErrorAction SilentlyContinue | Select-Object -First 1
        Write-Host ""
        Write-Host "  $IconInfo INTERFACE: $($config.InterfaceAlias)" -ForegroundColor Yellow
        Write-Host "  $IconArrow Local:   $($config.IPv4Address.IPAddress) [$((Get-NetAdapter -InterfaceIndex $config.InterfaceIndex).MacAddress)]"
        Write-Host "  $IconArrow Gateway: $($config.IPv4DefaultGateway.NextHop) [$($gwNeighbor.LinkLayerAddress)]"
        Write-Host ""
    }
    else { Write-Alert "No active gateway." }
}
Set-Alias mac Get-NetworkInfo

function Start-FileShare {
    param(
        [Parameter(Mandatory = $false)][int]$Port = 5000,
        [Parameter(Mandatory = $false)][Alias("f")][switch]$Full
    )
    if (-not (Get-Command dufs -ErrorAction SilentlyContinue)) { Write-Failure "Dufs not found."; return }
    $config = Get-NetIPConfiguration | Where-Object { $null -ne $_.IPv4DefaultGateway } | Select-Object -First 1
    $ip = if ($config) { $config.IPv4Address.IPAddress } else { "localhost" }
    Write-Host "`n  $IconInfo SERVER ACTIVE" -ForegroundColor Cyan
    Write-Host "  $IconArrow URL: http://$($ip):$Port"
    Write-Host "  $IconArrow Access: $(if ($Full) { 'FULL' } else { 'READ-ONLY' })"
    Write-Host "  [ Press Ctrl+C to stop ]`n" -ForegroundColor Gray
    if ($Full) { dufs . --port $Port --allow-all } else { dufs . --port $Port }
}
Set-Alias srv Start-FileShare

# =============================================================================
# >>>  MANAGEMENT & HELP                                                    <<<
# =============================================================================

function Edit-Profile { notepad $PROFILE }
Set-Alias ep Edit-Profile

function Update-Profile { 
    if (Test-Path $Global:ProfileSourcePath) { . $Global:ProfileSourcePath } else { . $PROFILE }
    Write-Success "Profile reloaded."
}
Set-Alias rl Update-Profile

function Show-ProfileHelp {
    $c = [char]27; $magenta = "$c[1;35m"; $cyan = "$c[1;36m"; $gray = "$c[90m"; $reset = "$c[0m"; $yellow = "$c[1;33m"
    
    Write-Host "`n  $magenta$IconInfo TERMINAL COMMAND CENTER$reset"
    Write-Host "  $gray$($LineChar * 55)$reset"
    
    $sections = @(
        @{ Title = "NAV & FILESYSTEM"; Cmds = @(
            @("mdc <path>", "New dir + CD"),
            @(".. / ...",    "Jump up 1 or 2 levels"),
            @("sf <query>",  "High-speed text search"),
            @("ds <path>",   "Directory size (recursive)"),
            @("touch <f>",   "Create/Update file"),
            @("unblock",     "Remove web-lock from files")
        )},
        @{ Title = "GIT WORKFLOW"; Cmds = @(
            @("gup <msg>",   "Auto-sync: add/com/pull/push"),
            @("gcl <url>",   "Clone + Auto-CD"),
            @("gnew <url>",  "Init + First Publish"),
            @("grem",        "Remove .git tracking"),
            @("Git Shorthands", "gst, gpl, gdf, glo, gco (Status, Pull, Diff, Log, Checkout)")
        )},
        @{ Title = "SYSTEM & NETWORK"; Cmds = @(
            @("update",      "Winget selection menu"),
            @("sync",        "Update profile modules/tools"),
            @("kp <port/id>", "Kill process (Auto-detect mode)"),
            @("srv [port]",  "Start HTTP file server"),
            @("ip / mac",    "Public IP / Local Network Info"),
            @("wh / clh",    "Cmd Source / Clear History")
        )},
        @{ Title = "PROFILE MANAGEMENT"; Cmds = @(
            @("ep",          "Edit Profile (Notepad)"),
            @("rl",          "Reload Profile changes"),
            @("hh",          "Show this command menu")
        )}
    )

    foreach ($s in $sections) {
        Write-Host "  $magenta$($s.Title) $($LineChar * (55 - $s.Title.Length - 4))$reset"
        foreach ($line in $s.Cmds) {
            $cmd = "$cyan$($line[0])$reset"
            $desc = if ($line.Count -gt 1) { "$gray - $($line[1])$reset" } else { "" }
            Write-Host "   $IconArrow $cmd$desc"
        }
        Write-Host ""
    }
    
    Write-Host "  $gray$($LineChar * 55)$reset"
    Write-Host "  $yellow Tip:$reset Use $cyan-WhatIf$reset for safe dry-runs on destructive commands.`n"
}
Set-Alias hh Show-ProfileHelp


