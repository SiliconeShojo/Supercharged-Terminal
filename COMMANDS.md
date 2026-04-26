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
# Search for "TODO" in current directory (default depth 3)
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
# Check size of current directory
dsize

# Check size of node_modules
dsize ./node_modules

# Check size with custom depth (e.g., depth 10)
dsize . 10
```

### `unblock`
Unblocks files in the current folder, which is often required for scripts downloaded from the internet.

```powershell
# Unblock files in current folder
unblock

# Recursively unblock everything in subfolders
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

## 🐙 Git Workflow

### `gs`, `gpl`, `gd`, `gl`
Shorthands for common Git operations with enhanced feedback.

```powershell
# Git Status
gs

# Git Pull (with feedback)
gpl

# Git Diff
gd

# Git Log (pretty graph with decorations)
gl
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
Clones a repository and automatically enters its directory. It accepts all standard `git clone` flags.

```powershell
# Standard clone and enter
gcl https://github.com/user/repo.git

# Clone with additional arguments
gcl https://github.com/user/repo.git --depth 1 --branch main my-folder
```

### `grem`
Safely removes the `.git` folder from the current directory to stop tracking.

```powershell
# Remove Git tracking
grem
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

### `myip`
Fetches your public IP address and automatically copies it to the clipboard.

```powershell
# Get public IP
myip
```

### `which`
Finds the source (file path or module) of a command.

```powershell
# Find where python is located
which python
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
