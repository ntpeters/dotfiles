Function Stop-PowerShell {
    <#
    .SYNOPSIS
    Stops all PowerShell instances of the specified type, optionally including the current instance.

    .PARAMETER Type
    The flavor of PowerShell instances to stop. Default is Current.
    Supported values:
        Core - PowerShell Core
        Windows - Windows PowerShell
        All - Both PowerShell Core and Windows PowerShell
        Current - The type of PowerShell instance the command was invoked from.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter()]
        [ValidateSet("Core", "Windows", "All", "Current")]
        [string] $Type = "Current",

        [Parameter()]
        [switch] $IncludeSelf
    )

    Write-Debug "Requested Type: $Type"

    # Get the flavor of the current PowerShell instance
    $CurrentPowerShellType = $(Get-Process -Id $PID).ProcessName
    Write-Debug "Current Type: $CurrentPowerShellType; Current PID: $PID"

    # Get the PowerShell process name(s) to kill
    $PowerShellTypesToKill = switch ($Type) {
        'Core' { 'pwsh' }
        'Windows' { 'powershell' }
        'All' { 'pwsh', 'powershell' }
        'Current' { $CurrentPowerShellType }
    }

    Write-Debug "Resolved Types To Kill: $PowerShellTypesToKill"

    # Get instances of the flavor(s) of PowerShell to kill
    $PowerShellInstancesToKill = Get-Process -Name $PowerShellTypesToKill -ErrorAction 'Ignore'

    Write-Debug "Current PID: $PID"
    Write-Debug "Found $($PowerShellInstancesToKill.Length) PowerShell Instances To Kill (pre-filtered): $($PowerShellInstancesToKill | Select-Object -Property Id,Name | Join-String -Separator ', ')"

    # Compose prompt segment stating the types of instances being killed
    $KillTypePromptSegment = [string]::Join(' or ', $PowerShellTypesToKill)

    # Optionally exclude the current instance
    $KillSelfPromptSegment = "including"
    if (-not $IncludeSelf) {
        $KillSelfPromptSegment = "excluding"

        Write-Debug "Removing current process from list of instances to kill: $PID"
        $PowerShellInstancesToKill = $PowerShellInstancesToKill | Where-Object -Property 'Id' -NE -Value $PID

        $CurrentParentProcessId = $PID
        while ($null -ne $CurrentParentProcessId) {
            $CurrentProcess = Get-CimInstance -Class Win32_Process -Filter "ProcessId = '$CurrentParentProcessId'"
            $CurrentParentProcessId = $CurrentProcess.ParentProcessId
            if (($null -ne $CurrentProcess) -and (($CurrentProcess.Name -eq 'pwsh.exe') -or ($CurrentProcess.Name -eq 'powershell.exe'))) {
                Write-Debug "Removing parent of current process from list of instances to kill: $($CurrentProcess.ParentProcessId)"
                $PowerShellInstancesToKill = $PowerShellInstancesToKill | Where-Object -Property 'Id' -NE -Value $CurrentProcess.ParentProcessId
                $CurrentParentProcessId = $CurrentProcess.ParentProcessId
            } else {
                Write-Debug "No remaining PowerShell parent processes of process: $CurrentParentProcessId"
                $CurrentParentProcessId = $null
            }
        }
    } elseif ($PowerShellTypesToKill -notcontains $CurrentPowerShellType) {
        throw "The 'IncludeSelf' flag was provided, but the current instance type (${CurrentPowerShellType}) was not included in the types to kill (${PowerShellTypesToKill})."
    }

    Write-Debug "Found $($PowerShellInstancesToKill.Length) PowerShell Instances To Kill (filtered): $($PowerShellInstancesToKill | Select-Object -Property Id,Name | Join-String -Separator ', ')"

    # Kill all matching instances
    if ($PowerShellInstancesToKill.Count -gt 0) {
        # Prompt for confirmation before killing the other PowerShell instances
        $PromptMessage = "Stopping $($PowerShellInstancesToKill.Count) ${KillTypePromptSegment} instances, ${KillSelfPromptSegment} the current ${CurrentPowerShellType} instance."
        $ShouldKillPowerShellInstances = [bool]($Host.UI.PromptForChoice($PromptMessage, "Continue?", @('&No', '&Yes'), 0))
        if ($ShouldKillPowerShellInstances) {
            Stop-Process -InputObject $PowerShellInstancesToKill -Force
        }
    } else {
        Write-Host "No matching ${KillTypePromptSegment} instances found."
    }
}

Set-Alias killps Stop-PowerShell