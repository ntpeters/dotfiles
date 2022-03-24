function Get-CommandTarget(
    [CmdletBinding()]
    [Parameter(Position=0, Mandatory=$true)]
    [string[]]
    $Name,
    [Parameter(Mandatory=$false)]
    [switch]
    $All,
    [Parameter(Mandatory=$false)]
    [System.Management.Automation.CommandTypes]
    $CommandType
)
{
    Write-Debug "Parameters: Name='$Name'; All='$All'; CommandType='$CommandType'"

    # Do not mimic the behavior of Get-Command that outputs all commands when either no names or just a wildcard are given
    if ([string]::IsNullOrWhiteSpace($Name) -or $Name -eq '*')
    {
        throw "Name parameter is required, and must not contain only a wildcard (*)."
    }

    Write-Debug "ErrorAction Settings: PSBoundParameters['ErrorAction']='$($PSBoundParameters['ErrorAction'])'; ErrorActionPreference='$ErrorActionPreference'"

    # Unless overriden by the caller suppress error output to mimic `which`.
    # User has overriden this either by explicitly setting ErrorAction or ErrorActionPreference to something other than the default value of Continue
    if ($PSBoundParameters['ErrorAction'] -or $ErrorActionPreference -ne 'Continue')
    {
        Write-Debug "ErrorAction for Get-Command overridden by caller: '$ErrorActionPreference'"

        # When ErrorAction is explicitly set, ErrorActionPreference is automatically set to that value for the scope
        if ($null -eq $CommandType)
        {
            $commands = Get-Command $Name -All:$All -ErrorAction:$ErrorActionPreference
        }
        else
        {
            $commands = Get-Command $Name -All:$All -CommandType:$CommandType -ErrorAction:$ErrorActionPreference
        }
    }
    else
    {
        Write-Debug "Using default ErrorAction for Get-Command: 'SilentlyContinue'"

        # Use SilentlyContinue rather than Ignore so that errors are still written to the $Error variable
        if ($null -eq $CommandType)
        {
            $commands = Get-Command $Name -All:$All -ErrorAction 'SilentlyContinue'
        }
        else
        {
            $commands = Get-Command $Name -All:$All -CommandType:$CommandType -ErrorAction 'SilentlyContinue'
        }
    }

    $foundCommands = @{}
    $commands.ForEach({
        $simplifiedCommandName = $(Split-Path $_.Name -Leaf).Split('.')[0].ToLower()
        $foundCommands[$simplifiedCommandName]++
    })
    Write-Debug "$($foundCommands.Count) of $($Name.Count) unique command(s) found, with a total of $($commands.Count) instance(s) for those found"

    if ($null -eq $commands)
    {
        Write-Debug "Setting LastExitCode=1 - No commands found"

        # Mimic `which` exit status
        $Global:LastExitCode = 1
        return $null
    }

    $results = @()
    $resolvedCommands = @{}
    foreach ($command in $commands)
    {
        $simplifiedCommandName = $(Split-Path $command.Name -Leaf).Split('.')[0].ToLower()
        $resolvedCommands[$simplifiedCommandName]++

        $results += Get-CommandInfo -Command $command -Recurse:$All
    }

    Write-Debug "$($resolvedCommands.Count) of $($commands.Count) found command(s) resolved successfully with a total of $($results.Count) results(s)"

    if ($resolvedCommands.Count -ne $Name.Count)
    {
        Write-Debug "Setting LastExitCode=1 - $($Name.Count - $resolvedCommands.Count) command(s) either not found or resolved"

        # Mimic `which` exit status for failure to find any of the given commands
        $Global:LastExitCode = 1
    }

    return $results
}

function Get-CommandInfo(
    [Parameter(Position=0, Mandatory=$true)]
    [System.Management.Automation.CommandInfo]
    $Command,
    [Parameter(Mandatory=$false)]
    [switch]
    $Recurse = $false
)
{
    if (-not [string]::IsNullOrWhiteSpace($Command.Module.Path))
    {
        $moduleInfo += "defined by module '$($Command.Module.Path)'"
    }
    elseif (-not [string]::IsNullOrWhiteSpace($Command.ModuleName))
    {
        $moduleInfo = "defined by module '$($Command.ModuleName)'"
    }

    $results = @()
    if ($Command.CommandType -eq 'Alias')
    {
        Write-Debug "Handled Command: Name='$($Command.Name)'; Type='$($Command.CommandType)'; Source='$($Command.Source)'; ModulePath='$($Command.Module.Path)'; Definition='$($Command.Definition)'"
        $results += "$($Command.Name): aliased to '$($Command.Definition)' $moduleInfo"

        if ($Recurse -and $null -ne $Command.ReferencedCommand)
        {
            $results += Get-CommandInfo -Command $Command.ReferencedCommand -Recurse
        }
    }
    elseif ($Command.CommandType -eq 'Function')
    {
        Write-Debug "Handled Command: Name='$($Command.Name)'; Type='$($Command.CommandType)'; Source='$($Command.Source)'; ModulePath='$($Command.Module.Path)'; Definition='$($Command.Definition)'"
        # $results += $Command.Definition
        $results += "$($Command.Name): function $moduleInfo"
    }
    elseif ($Command.CommandType -eq 'Cmdlet')
    {
        Write-Debug "Handled Command: Name='$($Command.Name)'; Type='$($Command.CommandType)'; Source='$($Command.Source)'; ModulePath='$($Command.Module.Path)'; Definition='$($Command.Definition)'"
        # $results += $Command.Definition
        $results += "$($Command.Name): cmdlet $moduleInfo"
    }
    elseif (-not [string]::IsNullOrWhiteSpace($Command.Source))
    {
        Write-Debug "Handled Command: Name='$($Command.Name)'; Type='$($Command.CommandType)'; Source='$($Command.Source)'; ModulePath='$($Command.Module.Path)'; Definition='$($Command.Definition)'"
        $results += $Command.Source
    }
    else
    {
        Write-Debug "Unhandled Command: Name='$($Command.Name)'; Type='$($Command.CommandType)'; Source='$($Command.Source)'; ModulePath='$($Command.Module.Path)'; Definition='$($Command.Definition)'"
        Write-Error "No source identified for command '$Name' of type '$($Command.CommandType)'"
    }

    return $results
}

Set-Alias which Get-CommandTarget