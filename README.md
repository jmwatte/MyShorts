# MyShorts - PowerShell Shortcut Manager

A PowerShell module for managing and quickly accessing frequently-used command shortcuts with categories and descriptions.

## Installation

1. Clone or download this repository to your PowerShell modules folder:
   ```powershell
   git clone https://github.com/jmwatte/MyShorts.git "$env:USERPROFILE\Documents\PowerShell\Modules\MyShorts"
   ```

2. Import the module:
   ```powershell
   Import-Module MyShorts
   ```

3. (Optional) Add to your PowerShell profile to load automatically:
   ```powershell
   Import-Module MyShorts
   ```

## Quick Start

### Adding Your First Shortcut

```powershell
# Add a simple shortcut
Add-MyShort -Name "ListFiles" -Command { Get-ChildItem } -Description "List all files"

# Add a shortcut with a category
Add-MyShort -Name "GitStatus" -Category "Git" -Command { git status } -Description "Check git status"

# Add a more complex command
Add-MyShort -Name "FindLargeFiles" -Category "Files" -Command { 
    Get-ChildItem -Recurse | Where-Object { $_.Length -gt 100MB } | Sort-Object Length -Descending 
} -Description "Find files larger than 100MB"
```

### Viewing Your Shortcuts

```powershell
# List all shortcuts
Get-MyShorts

# List shortcuts in a specific category
Get-MyShorts -Category "Git"

# See all categories you've created
Get-MyShortCategories
```

### Using Your Shortcuts

```powershell
# Run a shortcut directly
Invoke-MyShort -Name "GitStatus"

# Select a shortcut interactively with fzf (if installed)
Select-MyShort

# Run all shortcuts in a category
Get-MyShorts -Category "Git" | Invoke-MyShort
```

### Saving Your Shortcuts

```powershell
# Save shortcuts to persist across sessions
Save-MyShorts

# Reload shortcuts from file
Import-MyShorts
```

## Features

### Interactive Selection with fzf

If you have [fzf](https://github.com/junegunn/fzf) installed, `Select-MyShort` provides fuzzy search:

```powershell
Select-MyShort
```

This displays your shortcuts with descriptions, lets you search/filter, and then:
- Displays the selected command
- Adds it to your command history (press Up Arrow to recall)

### Tab Completion

The module includes smart tab completion:

```powershell
# Tab complete shortcut names
Invoke-MyShort -Name Git<Tab>

# Tab complete categories
Get-MyShorts -Category G<Tab>
```

### Pipeline Support

Work with shortcuts using PowerShell pipelines:

```powershell
# Run all shortcuts in a category
Get-MyShorts -Category "Maintenance" | Invoke-MyShort

# Remove old shortcuts with confirmation
Get-MyShorts -Category "Old" | Remove-MyShort -WhatIf
```

## Command Reference

### Add-MyShort
Adds a new shortcut.

**Parameters:**
- `-Name` (required): Unique name for the shortcut
- `-Command` (required): ScriptBlock to execute
- `-Description`: What the command does
- `-Category`: Category to organize shortcuts (default: "General")

**Example:**
```powershell
Add-MyShort -Name "UpdateModules" `
    -Category "Maintenance" `
    -Command { Update-Module -Force } `
    -Description "Update all PowerShell modules"
```

### Get-MyShorts
Lists stored shortcuts.

**Parameters:**
- `-Category`: Filter by category (optional)

**Example:**
```powershell
Get-MyShorts
Get-MyShorts -Category "Git"
```

### Invoke-MyShort
Executes a shortcut by name.

**Parameters:**
- `-Name` (required): The shortcut to run

**Example:**
```powershell
Invoke-MyShort -Name "GitStatus"
```

### Set-MyShort
Updates an existing shortcut (or creates if it doesn't exist).

**Parameters:**
- Same as `Add-MyShort`

**Example:**
```powershell
Set-MyShort -Name "GitStatus" -Command { git status --short } -Description "Git status (short)"
```

### Remove-MyShort
Deletes a shortcut.

**Parameters:**
- `-Name` (required): The shortcut to remove
- `-WhatIf`: Preview what would be removed
- `-Confirm`: Prompt for confirmation

**Example:**
```powershell
Remove-MyShort -Name "OldShortcut"
Remove-MyShort -Name "Test" -WhatIf
```

### Select-MyShort
Interactive shortcut selection using fzf or Out-GridView.

**Parameters:**
- `-Category`: Filter to a specific category (optional)

**Example:**
```powershell
Select-MyShort
Select-MyShort -Category "Git"
```

### Save-MyShorts
Saves shortcuts to a JSON file in the module directory.

**Example:**
```powershell
Save-MyShorts
```

### Import-MyShorts
Reloads shortcuts from the JSON file.

**Example:**
```powershell
Import-MyShorts
```

### Get-MyShortCategories
Lists all unique categories.

**Example:**
```powershell
Get-MyShortCategories
```

## Real-World Examples

### Git Shortcuts
```powershell
Add-MyShort -Name "GitPull" -Category "Git" -Command { 
    git pull --rebase 
} -Description "Pull with rebase"

Add-MyShort -Name "GitCommit" -Category "Git" -Command { 
    git add -A; git commit 
} -Description "Stage all and commit"

Add-MyShort -Name "GitLog" -Category "Git" -Command { 
    git log --oneline --graph --all -20 
} -Description "Pretty git log (last 20)"
```

### File Management
```powershell
Add-MyShort -Name "CleanTemp" -Category "Maintenance" -Command { 
    Remove-Item $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue 
} -Description "Clean temp folder"

Add-MyShort -Name "DiskSpace" -Category "System" -Command { 
    Get-PSDrive -PSProvider FileSystem | Select-Object Name, Used, Free 
} -Description "Show disk space"
```

### Development Shortcuts
```powershell
Add-MyShort -Name "BuildRelease" -Category "Build" -Command { 
    dotnet build -c Release 
} -Description "Build in release mode"

Add-MyShort -Name "TestWatch" -Category "Testing" -Command { 
    dotnet watch test 
} -Description "Run tests in watch mode"
```

## Tips & Best Practices

1. **Organize with Categories**: Use categories to group related shortcuts (Git, Files, Build, etc.)

2. **Add Descriptions**: Always add descriptions—they show up in `Select-MyShort` and help you remember what each shortcut does

3. **Save Regularly**: Run `Save-MyShorts` after adding shortcuts to persist them

4. **Use Variables in Commands**: You can reference variables in your scriptblocks:
   ```powershell
   Add-MyShort -Name "GoToProject" -Command { 
       Set-Location "C:\Projects\MyApp" 
   }
   ```

5. **Complex Commands**: For multi-line commands, use scriptblocks:
   ```powershell
   Add-MyShort -Name "Backup" -Command {
       $date = Get-Date -Format "yyyyMMdd"
       Copy-Item -Path ".\data" -Destination ".\backup_$date" -Recurse
       Write-Host "Backup created: backup_$date"
   }
   ```

6. **Sync Across Machines**: Since shortcuts are stored in the module directory, commit `MyShorts.json` to your git repository to share shortcuts across machines

## Troubleshooting

**Shortcuts not persisting?**
- Make sure to run `Save-MyShorts` after adding shortcuts
- Check that `MyShorts.json` exists in the module directory

**Tab completion not working?**
- Reload the module: `Import-Module MyShorts -Force`
- Make sure you're using PowerShell 5.1 or later

**Select-MyShort not working?**
- Install fzf: `winget install fzf` (Windows) or `brew install fzf` (Mac)
- Or it will fall back to `Out-GridView` on Windows

## Storage Location

Shortcuts are stored in: `<ModuleDirectory>\MyShorts.json`

You can find your module directory with:
```powershell
(Get-Module MyShorts).ModuleBase
```

## Contributing

Issues and pull requests welcome at: https://github.com/jmwatte/MyShorts

## License

MIT License - Feel free to use and modify as needed.
