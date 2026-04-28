# PowerShell Profile Suite
### A Native-First Configuration for Modern PowerShell

---

## Overview
This repository contains a curated PowerShell configuration designed for efficient terminal workflows. It prioritizes native PowerShell logic for core tasks and integrates common tools for a consistent experience across Windows environments.

![Main Terminal Screenshot](Terminal.png)

---

## Features

### 🎨 Visuals & Themes
*   **Prompt Customization**: Prompt themes for real-time status and aesthetic consistency.
*   **Icon Support**: Integrated icons for enhanced directory and file visibility.
*   **Nerd Font Ready**: Optimized for modern font families with complete glyph support.

### 🧠 Intelligence & Workflow
*   **Predictive Autocomplete**: Context-aware command suggestions based on your history and active plugins.
*   **Native Search Utility**: Optimized, regex-capable search engine with grouped and color-coded results.
*   **Update Dashboard**: Multi-source manager for package updates across different providers.
*   **Git Automation**: Streamlined synchronization workflow for staging, committing, and pushing.

---

## Installation

### 1. Prerequisite: Nerd Font
Icons require a **Nerd Font** to be active in your terminal emulator.
1.  Install a compatible font (e.g., [JetBrainsMono Nerd Font](https://www.nerdfonts.com/)).
2.  In **Windows Terminal**: `Settings > Profiles > PowerShell > Appearance > Font Face`.

### 2. Automated Setup
Execute the following in a PowerShell window running as **Administrator**:
```powershell
irm https://raw.githubusercontent.com/SiliconeShojo/Supercharged-Terminal/main/install.ps1 | iex
```

---

## Documentation
A full list of commands and aliases is available in the [Command Reference](COMMANDS.md).

---

> [!TIP]
> **Choosing a Font Family:**
> *   **Nerd Font Mono (NFM)**: Use this if your terminal requires strict character widths (monospacing).
> *   **Standard Nerd Font (NF)**: Use this for modern terminals to get larger, more readable icons that can occupy more than one character width.

> [!TIP]
> **Changing Themes:**
> 1. Browse the [Oh My Posh Gallery](https://ohmyposh.dev/docs/themes) for a theme name.
> 2. Open your profile for editing (run `ep`).
> 3. Locate the `$ThemePath` variable and update the filename (e.g., `montys.omp.json`).
> 4. Reload your profile to apply the changes (run `rl`).

---
*Happy Coding.* 🚀