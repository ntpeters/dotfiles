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
    Param (
        [Parameter()]
        [ValidateSet("Core", "Windows", "All", "Current")]
        [string] $Type = "Current",

        [Parameter()]
        [switch] $IncludeSelf
    )

    # Get the flavor of the current PowerShell instance
    $CurrentPowerShellType = $(Get-Process -Id $PID).ProcessName

    # Get the PowerShell process name(s) to kill
    $PowerShellTypesToKill = Switch ($Type) {
        'Core' { 'pwsh' }
        'Windows' { 'powershell' }
        'All' { 'pwsh', 'powershell' }
        'Current' { $CurrentPowerShellType }
    }

    # Get instances of the flavor(s) of PowerShell to kill
    $PowerShellInstancesToKill = Get-Process -Name $PowerShellTypesToKill -ErrorAction 'Ignore'

    # Compose prompt segment stating the types of instances being killed
    $KillTypePromptSegment = [string]::Join(' or ', $PowerShellTypesToKill)

    # Optionally exclude the current instance
    $KillSelfPromptSegment = "including"
    If (-Not $IncludeSelf) {
        $KillSelfPromptSegment = "excluding"
        $PowerShellInstancesToKill = $PowerShellInstancesToKill | Where-Object -Property 'Id' -NE -Value $PID
    } ElseIf ($PowerShellTypesToKill -NotContains $CurrentPowerShellType) {
        Throw "The 'IncludeSelf' flag was provided, but the current instance type (${CurrentPowerShellType}) was not included in the types to kill (${PowerShellTypesToKill})."
    }

    # Kill all matching instances
    If ($PowerShellInstancesToKill.Count -gt 0) {
        # Prompt for confirmation before killing the other PowerShell instances
        $PromptMessage = "Stopping $($PowerShellInstancesToKill.Count) ${KillTypePromptSegment} instances, ${KillSelfPromptSegment} the current ${CurrentPowerShellType} instance."
        $ShouldKillPowerShellInstances = [bool]($Host.UI.PromptForChoice($PromptMessage, "Continue?", @('&No', '&Yes'), 0))
        If ($ShouldKillPowerShellInstances) {
            Stop-Process -InputObject $PowerShellInstancesToKill -Force
        }
    } Else {
        Write-Host "No matching ${KillTypePromptSegment} instances found."
    }
}

Set-Alias killps Stop-PowerShell