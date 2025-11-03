# MyShorts.psm1
# A simple shortcut manager with categories

$script:MyShorts = @{}
$script:StoragePath = Join-Path $env:USERPROFILE "MyShorts.json"

function Initialize-MyShorts {
    if (Test-Path $script:StoragePath) {
        try {
            $data = Get-Content $script:StoragePath | ConvertFrom-Json
            # Convert back to hashtable with scriptblocks
            foreach ($key in $data.PSObject.Properties.Name) {
                $script:MyShorts[$key.Trim()] = @{
                    Command     = [scriptblock]::Create($data.$key.Command)
                    Description = $data.$key.Description
                    Category    = $data.$key.Category
                }
            }
        } catch {
            Write-Warning "Failed to load shortcuts from $script:StoragePath. Starting with empty shortcuts."
            $script:MyShorts = @{}
        }
    }
}

function Set-MyShortEntry {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$Command,

        [string]$Description = "",

        [string]$Category = "General"
    )

    $script:MyShorts[$Name] = @{
        Command     = $Command
        Description = $Description
        Category    = $Category
    }
}

function Add-MyShort
{
    <#
.SYNOPSIS
    Adds a new shortcut command.

.DESCRIPTION
    Stores a command in the MyShorts hashtable with a name, category,
    description, and scriptblock to execute.

.PARAMETER Name
    The shortcut name (unique key).

.PARAMETER Command
    The scriptblock or command to run.

.PARAMETER Description
    A short explanation of what the command does.

.PARAMETER Category
    A category label to group related shortcuts.

.EXAMPLE
    Add-MyShort -Name "GetTags" -Category "Tagging" -Command { Get-OmTags . -Summary } -Description "Summarizes tags"

    Adds a shortcut named GetTags in the Tagging category.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$Command,

        [string]$Description = "",

        [string]$Category = "General"
    )

    if ($script:MyShorts.ContainsKey($Name)) {
        Write-Warning "Shortcut '$Name' already exists. Use Set-MyShort to update it."
        return
    }

    Set-MyShortEntry -Name $Name.Trim() -Command $Command -Description $Description -Category $Category
    Write-Verbose "Added shortcut '$Name'."
}

function Get-MyShorts
{
    <#
.SYNOPSIS
    Lists stored shortcuts.

.DESCRIPTION
    Displays all shortcuts with their name, category, and description.
    You can filter by category.

.PARAMETER Category
    Optional. Only return shortcuts in this category.

.EXAMPLE
    Get-MyShorts

    Lists all shortcuts.

.EXAMPLE
    Get-MyShorts -Category "Tagging"

    Lists only shortcuts in the Tagging category.
#>
    [CmdletBinding()]
    param(
        [string]$Category
    )

    $entries = $script:MyShorts.GetEnumerator() | ForEach-Object {
        [PSCustomObject]@{
            Name        = $_.Key
            Category    = $_.Value.Category
            Description = $_.Value.Description
        }
    }

    if ($Category)
    {
        $entries | Where-Object { $_.Category -eq $Category }
    } else
    {
        $entries
    }
}

function Invoke-MyShort
{
    <#
.SYNOPSIS
    Runs a stored shortcut.

.DESCRIPTION
    Executes the scriptblock associated with a shortcut by name.

.PARAMETER Name
    The shortcut name to run.

.EXAMPLE
    Invoke-MyShort -Name "GetTags"

    Runs the GetTags shortcut.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    if ($script:MyShorts.ContainsKey($Name))
    {
        try {
            & $script:MyShorts[$Name].Command
        } catch {
            Write-Error "Failed to execute shortcut '$Name': $_"
        }
    } else
    {
        Write-Warning "No shortcut named '$Name' found."
    }
}

function Set-MyShort
{
    <#
.SYNOPSIS
    Updates an existing shortcut.

.DESCRIPTION
    Overwrites the command, description, or category of an existing shortcut.
    If the shortcut does not exist, it will be created.

.PARAMETER Name
    The shortcut name.

.PARAMETER Command
    The scriptblock or command to run.

.PARAMETER Description
    A short explanation of what the command does.

.PARAMETER Category
    A category label to group related shortcuts.

.EXAMPLE
    Set-MyShort -Name "GetTags" -Category "Tagging" -Command { Get-OmTags . -Summary -Verbose } -Description "Summarizes tags with verbose output"
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$Command,

        [string]$Description = "",

        [string]$Category = "General"
    )

    Set-MyShortEntry -Name $Name.Trim() -Command $Command -Description $Description -Category $Category
    Write-Verbose "Set shortcut '$Name'."
}

function Remove-MyShort
{
    <#
.SYNOPSIS
    Deletes a shortcut.

.DESCRIPTION
    Removes a shortcut from the MyShorts hashtable.

.PARAMETER Name
    The shortcut name to remove.

.EXAMPLE
    Remove-MyShort -Name "GetTags"

    Deletes the GetTags shortcut.
#>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    if ($script:MyShorts.ContainsKey($Name))
    {
        if ($PSCmdlet.ShouldProcess($Name, "Remove shortcut")) {
            $script:MyShorts.Remove($Name) | Out-Null
            Write-Verbose "Removed shortcut '$Name'."
        }
    } else
    {
        Write-Warning "No shortcut named '$Name' found."
    }
}

function Select-MyShort
{
    <#
.SYNOPSIS
    Interactive selection of shortcuts.

.DESCRIPTION
    Uses fzf to select a shortcut by name (optionally filtered by category)
    and inserts the command into the prompt for editing or execution.

.PARAMETER Category
    Optional. Only show shortcuts in this category.

.EXAMPLE
    Select-MyShort

    Shows all shortcuts in fzf for selection.

.EXAMPLE
    Select-MyShort -Category "Tagging"

    Shows only Tagging shortcuts in fzf.
#>
    [CmdletBinding()]
    param(
        [string]$Category
    )

    $entries = if ($Category)
    {
        Get-MyShorts -Category $Category
    } else
    {
        Get-MyShorts
    }

    if (Get-Command fzf -ErrorAction SilentlyContinue) {
        $choice = ($entries | ForEach-Object { $_.Name } | fzf).Trim()
        if ($choice)
        {
            $command = $script:MyShorts[$choice].Command.ToString()
            Write-Host "Selected command: $command"
            # if (Get-Module PSReadLine -ErrorAction SilentlyContinue) {
            #     [Microsoft.PowerShell.PSConsoleReadLine]::Insert($command)
            # } else {
            #     Write-Host $command
            # }
        }
    } elseif (Get-Command Out-GridView -ErrorAction SilentlyContinue) {
        $choice = $entries | Out-GridView -Title "Select a shortcut" -OutputMode Single
        if ($choice)
        {
            $command = $script:MyShorts[$choice.Name].Command.ToString()
            Write-Host "Selected command: $command"
            # if (Get-Module PSReadLine -ErrorAction SilentlyContinue) {
            #     [Microsoft.PowerShell.PSConsoleReadLine]::Insert($command)
            # } else {
            #     Write-Host $command
            # }
        }
    } else {
        Write-Warning "Neither fzf nor Out-GridView is available for interactive selection."
    }
}

function Save-MyShorts
{
    <#
.SYNOPSIS
    Saves the current shortcuts to a JSON file.

.DESCRIPTION
    Persists the shortcuts to the storage file for future sessions.

.EXAMPLE
    Save-MyShorts

    Saves all shortcuts to the default storage file.
#>
    [CmdletBinding()]
    param()

    try {
        $data = @{}
        foreach ($key in $script:MyShorts.Keys) {
            $data[$key] = @{
                Command     = $script:MyShorts[$key].Command.ToString()
                Description = $script:MyShorts[$key].Description
                Category    = $script:MyShorts[$key].Category
            }
        }
        $data | ConvertTo-Json | Set-Content $script:StoragePath
        Write-Verbose "Shortcuts saved to $script:StoragePath"
    } catch {
        Write-Error "Failed to save shortcuts: $_"
    }
}

function Import-MyShorts
{
    <#
.SYNOPSIS
    Imports shortcuts from the JSON file.

.DESCRIPTION
    Reloads shortcuts from the storage file, overwriting current shortcuts.

.EXAMPLE
    Import-MyShorts

    Imports shortcuts from the default storage file.
#>
    [CmdletBinding()]
    param()

    Initialize-MyShorts
    Write-Verbose "Shortcuts imported from $script:StoragePath"
}

# Initialize shortcuts on module import
Initialize-MyShorts

Export-ModuleMember -Function Add-MyShort, Get-MyShorts, Invoke-MyShort, Set-MyShort, Remove-MyShort, Select-MyShort, Save-MyShorts, Import-MyShorts
