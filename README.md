# ⚡ Supercharged Terminal
### A Professional PowerShell Environment for Windows

![PowerShell](https://img.shields.io/badge/PowerShell-7.4+-%235391FE?style=for-the-badge&logo=powershell&logoColor=white)

<br>

![Main Terminal Screenshot](Terminal.png)
*Above: The fully configured terminal running Oh My Posh, Terminal Icons, and Predictive Autocomplete.*

<br>

## ✨ Key Features

- **Professional Feedback System**: Integrated status icons for Success, Info, Warning, Error, and Busy states.
- **Advanced Navigation**: Smart directory creation, recursive unblocking, and size calculation.
- **Git Power-User Tools**: "Platinum" repository initialization, auto-syncing, and decorated log graphs.
- **System Optimizer**: Port-aware process killing, Winget update manager, and terminal history purging.
- **Intelligent Autocomplete**: Predicting your next command based on deep history and plugin context.

<br>

![Separator](https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif)

<br>

## 🚀 Quick Start (Auto-Install)

The fastest way to get started is using the automated installer which configures your entire environment in seconds.

> **Administrator Privileges Required**: The installer requires Admin rights to install system packages. The script will automatically request elevation if needed.

### 1. Mandatory Pre-requisite: Install & Apply a Nerd Font
Before running the installer, you **must** have a Nerd Font installed and active in your terminal. This ensures icons render correctly as soon as the installation completes.

**Step A: Pick and Install your font family:**
* If you are limited to monospaced fonts (because of your terminal, etc) then pick a font with `Nerd Font Mono` (or `NFM`).
* If you want to have bigger icons (usually around 1.5 normal letters wide) pick a font without `Mono` i.e. `Nerd Font` (or `NF`)

We recommend [FiraCode Nerd Font](https://www.nerdfonts.com/font-downloads) or [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads).

**Step B: Apply it to Windows Terminal:**
1.  Open **Windows Terminal Settings** (`Ctrl + ,`).
2.  Go to **Profiles** -> **PowerShell** (or Defaults).
3.  Select **Appearance**.
4.  Set **Font Face** to your installed Nerd Font (e.g., `FiraCode Nerd Font` or `JetBrainsMono NF`).
5.  Click **Save**.

### 2. The One-Liner
Once the font is applied, run this in a standard PowerShell window:
```powershell
irm https://raw.githubusercontent.com/SiliconeShojo/Supercharged-Terminal/main/install.ps1 | iex
```

> [!TIP]
> This script handles PowerShell 7, Oh My Posh, and your profile configuration automatically.

<br>

![Separator](https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif)

<br>

## 📖 Command Reference

For a complete list of commands, aliases, and detailed usage examples, please see the dedicated documentation page:

### 👉 [View Full Command Reference](COMMANDS.md)

---

### 🎨 Themes & Customization
Powered by **Oh My Posh**, you can switch styles instantly.

1.  **Browse:** Check the [Official Gallery](https://ohmyposh.dev/docs/themes).
2.  **Edit:** Run `pro`.
3.  **Change:** Update the `--config` path in the `oh-my-posh init` line.
4.  **Reload:** Run `ref`.

<br>

![Separator](https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif)

<br>

## 📊 Performance & Compatibility
*   **Engine**: Optimized for PowerShell 7.4+.
*   **Encoding**: Forced UTF-8 for icon fidelity.
*   **Async**: Posh-Git status is non-blocking.
*   **Compatibility**: Fallbacks included for PowerShell 5.1 where possible.

<br>

<p align="center">
  <img src="https://count.getloli.com/get/@SuperchargedTerminal?theme=booru-lewd" alt="Visitor Count">
</p>

<br>

*Terminal Supercharged. Happy Coding!* 🚀