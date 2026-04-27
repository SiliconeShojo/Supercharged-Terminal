# 📖 Command Reference

This page provides a detailed breakdown of all the aliases and custom commands available in the Supercharged Terminal profile.

---

## 📂 Navigation & Filesystem

### `mkcd`
Creates a new directory and immediately enters it.

```powershell
# Create and enter a new project folder
mkcd my-awesome-project
```

### `touch`
Creates a new empty file or updates the timestamp of an existing one.

```powershell
# Create a new file
touch server.js

# Update timestamp of an existing file
touch README.md
```

### `fxt`
Searches for a text pattern within files, automatically excluding common development folders like `.git`, `node_modules`, `dist`, etc.

> [!NOTE]
> **Depth** refers to how many subfolder levels to search. A depth of `3` (default) means it searches the current folder plus three levels of subdirectories.

```powershell
# Search for "TODO" (Recommended Args: <path> | -MaxDepth 5)
fxt "TODO"

# Search for "password" in a specific path
fxt "password" "C:\Users\Documents"

# Search with custom depth
fxt "main" . 10
```

### `dsize`
Calculates the total size of a directory by scanning its contents up to a specific depth.

> [!NOTE]
> The default depth is `5`. This ensures fast calculation even in large projects by avoiding deep system or dependency folders.

```powershell
# Check size (Recommended Args: -MaxDepth 10)
dsize

# Check size of node_modules
dsize ./node_modules

# Check size with custom depth (e.g., depth 10)
dsize . 10
```

### `unblock`
Unblocks files in the current folder, which is often required for scripts downloaded from the internet.

```powershell
# Unblock files (Recommended Args: <path> | -Recurse | -MaxDepth 3)
unblock

# Unblock a specific folder
unblock ./downloads

# Recursively unblock to a specific depth
unblock -MaxDepth 2

# Full recursion
unblock -Recurse
```

### `..` and `...`
Quick navigation to parent directories.

```powershell
# Move up one level
..

# Move up two levels
...
```

---

### 💡 Pro Tip: Customizing Depth (fxt, dsize, unblock)

Utility commands like **`fxt`**, **`dsize`**, and **`unblock`** can be run in two ways depending on which settings you want to change.

#### 🚀 Option A: The "Fast" Way (In Order)
If you provide values in the correct order, you don't need to type the "dashed" names. PowerShell reads them from left to right.

```powershell
# fxt/unblock Order: <pattern/path> <path/depth> <depth>
fxt "main" . 10       # Search current folder
unblock ./downloads 2 # Unblock downloads folder (Depth 2)
```

#### 🎯 Option B: The "Precise" Way (Using Names)
If you want to **skip** an argument (for example: search the current folder but change the depth), use the parameter name with a dash.

```powershell
# This skips the <path> and goes straight to depth
fxt "main" -MaxDepth 5
```

---

## 🐙 Git Workflow

### `gst`, `gpl`, `gdf`, `glo`
Shorthands for common Git operations. Running these without arguments will show curated popular flags.

```powershell
# Git Status (Recommended Args: -s -b)
gst

# Git Pull (Recommended Args: --rebase | --autostash)
gpl

# Git Diff (Recommended Args: --staged | --stat)
gdf

# Git Log (Recommended Args: --oneline --graph --decorate)
glo
```

### `gco`
Git Checkout shorthand.

```powershell
# Checkout a branch
gco my-feature

# Checkout and create new branch
gco -b hotfix-123

# Switch back to previous branch
gco -
```

### `gup`
Auto-syncs the current branch with origin. It adds all changes, commits with a message, pulls from origin with rebase, and pushes.

```powershell
# Sync changes with a message
gup "feat: implement user authentication"
```

### `gnew`
Initializes a new Git repository, performs the initial commit on `main`, adds a remote origin, and pushes.

```powershell
# Initialize and push to a new repo
gnew https://github.com/user/my-new-repo.git
```

### `gcl`
Clones a repository and automatically enters its directory. It supports a "Jump In" feature that handles standard and custom folder naming.

```powershell
# Standard clone and enter
gcl https://github.com/user/repo.git

# Clone a specific branch with curated depth
gcl https://github.com/user/repo.git -b main --depth 1

# Clone into a custom folder
gcl https://github.com/user/repo.git my-folder
```

### `grem`
Safely removes the `.git` folder from the current directory to stop tracking.

```powershell
# Remove Git tracking
grem
```

---

## 🌐 Network Utilities

### `mac`
Retrieves IP and MAC addresses for the local PC and its default gateway.

```powershell
# Get network details (IP and MAC)
mac
```

### `myip`
Fetches your public IP address and automatically copies it to the clipboard.

```powershell
# Get public IP
myip
```

### `share`
Instantly turns the current directory into a web server with a modern GUI for uploading and downloading files.

```powershell
# Start file sharing (Default Port: 5000)
share

# Start on a custom port
share 8081
```

---

## ⚙️ System & Process

### `kproc`
Stops processes based on their name or the port they are listening on.

```powershell
# Kill process listening on port 8080
kproc 8080

# Kill process by name (wildcard supported)
kproc "node"
```

### `which`
Finds the source (file path or module) of a command.

```powershell
# Find where python is located (Recommended Args: -All)
which python

# See all sources if multiple exist
which -All node
```

### `clh`
Clears the terminal history both in the current session and in the persistent history file.

```powershell
# Purge all history
clh
```

### `update`
Checks for and installs application updates via Winget using an interactive selection menu.

```powershell
# Start update manager
update
```

### `sync`
Synchronizes and updates the core internal dependencies used by this profile (Modules and Binary tools).

```powershell
# Update profile dependencies
sync
```

---

## 🛠 Profile Management

### `pro`
Opens your PowerShell profile in Notepad for quick editing.

```powershell
# Edit profile
pro
```

### `ref`
Reloads the PowerShell profile to apply changes without restarting the terminal.

```powershell
# Refresh environment
ref
```

### `menu`
Displays an interactive command cheat sheet directly in your terminal.

```powershell
# Show help menu
menu
```
