# 📖 Command Reference



## 📂 Navigation & Filesystem


### `mdc` (Initialize-Directory)
- **Purpose**: Creates a new directory and immediately changes the terminal location to it.
- **Parameters**:
  - `Path`: (Mandatory) The name or path of the directory to create.
- **Usage**:
  ```powershell
  mdc "my-new-project"
  ```

### `..` / `...`
- **Purpose**: Fast directory jumping.
- **Usage**:
  - `..`: Move up one level.
  - `...`: Move up two levels.

### `sf` (Select-FileText)
- **Purpose**: A high-performance text search utility. Uses a robust native engine for instant results while ignoring junk folders.
- **Parameters**:
  - `Pattern`: (Mandatory, **Positional 1**) Text or regex to search for. No flag needed.
  - `Path`: (Optional, **Positional 2**, Default: `.`) The search root.
  - `MaxDepth` [**-d**]: (Optional, Default: `Full Recursion`) Folder recursion depth.
- **Usage**:
  ```powershell
  sf "apiKey"          # Basic search (detected as Pattern)
  sf "TODO" src -d 5   # Search src folder, 5 levels deep
  ```

### `ds` (Get-DirectorySize)
- **Purpose**: Quickly calculates the total size of a directory **recursively** (includes all subfolders).
- **Parameters**:
  - `Path`: (Optional, Default: `.`) Target folder.
  - `MaxDepth` [**-d**]: (Optional, Default: `Full Recursion`) How many subfolders deep to calculate.
- **Usage**:
  ```powershell
  ds
  ds -d 2              # Only look 2 subfolders deep
  ```

### `touch` (Set-TouchFile)
- **Purpose**: Creates an empty file or updates the "Last Modified" timestamp.
- **Parameters**:
  - `Path`: (Mandatory) File to create/touch.
- **Usage**:
  ```powershell
  touch "index.html"
  ```

### `unblock` (Unblock-FolderFiles)
- **Purpose**: Recursively removes the "Downloaded from Internet" block from files.
- **Parameters**:
  - `Path`: (Optional, Default: `.`) Target folder.
  - `MaxDepth` [**-d**]: (Optional) Limit recursion depth.
  - `Recurse` [**-r**]: (Switch) Unblock all subfolders.
- **Usage**:
  ```powershell
  unblock C:\Downloads -r  # Unblock everything in Downloads
  unblock -d 1             # Unblock current folder + immediate subfolders
  ```

> [!NOTE]
> **Understanding Depth (`-d`)**
> Several commands (`sf`, `ds`, `unblock`) use a depth parameter to limit how far the tool "digs" into your folders:
> - **`-d 0`**: Current directory only (no subfolders).
> - **`-d 1`**: Current directory + immediate subfolders.
> - **`-d 2`**: Current directory + subfolders + their subfolders.
> - **No flag**: Performs **Full Recursion** (searches every file and folder in the entire tree).

---

## 🐙 Git Workflow

### Git Shorthands
These commands are high-speed wrappers around standard Git commands. They pass all arguments directly to Git, meaning you can use any flag or parameter supported by the underlying command.

- **`gst`** [`git status`]: View the state of your working directory.
- **`gpl`** [`git pull`]: Fetch from and integrate with another repository or a local branch.
- **`gdf`** [`git diff`]: Show changes between commits, commit and working tree, etc.
- **`glo`** [`git log`]: Show commit logs. (Default: `--oneline --graph --decorate -n 10`)
- **`gco`** [`git checkout`]: Switch branches or restore working tree files.

**Advanced Usage Examples**:
```powershell
gst -s                # Short status format
gco -b "feat/api"     # Create and switch to new branch
gdf --cached          # View changes staged for commit
glo -n 50             # View last 50 commits instead of 10
gpl --rebase          # Pull and rebase (recommended)
```

### `gup` (Sync-GitBranch)
- **Purpose**: Full sync: adds all changes, commits, pulls, and pushes.
- **Parameters**:
  - `Message`: (Mandatory) The commit message.
- **Usage**:
  ```powershell
  gup "Fixed mobile responsiveness"
  ```

### `gnew` (Initialize-GitRepo)
- **Purpose**: Initializes local repo and publishes to a remote URL.
- **Parameters**:
  - `RepoUrl`: (Mandatory) Remote Git URL.
- **Usage**:
  ```powershell
  gnew "https://github.com/user/project.git"
  ```

### `gcl` (Copy-GitRepo)
- **Purpose**: Clones a repository and **automatically** enters the folder.
- **Parameters**:
  - `Url`: (Mandatory) The Git URL to clone.
  - `GitArgs`: (Optional) Additional git clone arguments.
- **Usage**:
  ```powershell
  gcl "https://github.com/user/project.git" --depth 1
  ```

### `grem` (Remove-GitRepo)
- **Purpose**: Deletes the `.git` tracking folder.
- **Usage**:
  ```powershell
  grem
  ```

---

## ⚙️ System & Process

### `kp` (Stop-ProcessByNameOrPort)
- **Purpose**: Kills processes by **Port** or **Name**. Automatically detects the target type.
- **Parameters**:
  - `Identifier`: (Mandatory, **Positional 1**) A Port number (e.g., `3000`) or a Process Name (e.g., `node`).
- **Usage**:
  ```powershell
  kp 3000           # Detects number -> Kills port 3000
  kp node           # Detects string -> Kills processes matching "node"
  ```

### `wh` (Get-CommandSource)
- **Purpose**: Shows the source path or definition of **any** command (Function, Alias, or external Tool).
- **Parameters**:
  - `Name`: (Mandatory, **Positional 1**) Command name.
  - `All` [**-a**]: (Switch) Show all instances.
- **Usage**:
  ```powershell
  wh node           # Shows path to external tool
  ```

### `clh` (Clear-TerminalHistory)
- **Purpose**: Wipes session and persistent history.
- **Usage**:
  ```powershell
  clh
  ```

### `update` (Update-SystemPackages)
- **Purpose**: Interactive `winget upgrade` wrapper with visual diffing.
- **Usage**:
  ```powershell
  update
  ```

### `sync` (Update-ProfileDependencies)
- **Purpose**: Updates `oh-my-posh`, `dufs`, and profile modules.
- **Usage**:
  ```powershell
  sync
  ```

---

## 🌐 Network & Server

### `ip` (Get-PublicIP)
- **Purpose**: Public IP to clipboard.
- **Usage**:
  ```powershell
  ip
  ```

### `mac` (Get-NetworkInfo)
- **Purpose**: Summary of local network details.
- **Usage**:
  ```powershell
  mac
  ```

### `srv` (Start-FileShare)
- **Purpose**: Launches `dufs` file server. Defaults to Read-Only.
- **Parameters**:
  - `Port`: (Optional, Default: `5000`) Server port.
  - `Full` [**-f**]: (Switch) Enables Write/Delete permissions.
- **Usage**:
  ```powershell
  srv                # Safe Mode
  srv 8080 -f        # Admin Mode on port 8080
  ```

---

## 🛠 Profile Management

### `ep` (Edit-Profile)
- **Purpose**: Open profile in Notepad.
- **Usage**:
  ```powershell
  ep
  ```

### `rl` (Update-Profile)
- **Purpose**: Reload profile instantly.
- **Usage**:
  ```powershell
  rl
  ```

### `hh` (Show-ProfileHelp)
- **Purpose**: Show terminal cheat sheet.
- **Usage**:
  ```powershell
  hh
  ```

---
