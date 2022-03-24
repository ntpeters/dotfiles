# Only import the module once.
If (Get-Module ntpetersUtil) {
    return
}

$Script:ScriptDirectory = (Split-Path -Parent $MyInvocation.MyCommand.Definition)

. $Script:ScriptDirectory\functions\Export-Variable.ps1
. $Script:ScriptDirectory\functions\Invoke-Exa.ps1
. $Script:ScriptDirectory\functions\Show-Colors.ps1
. $Script:ScriptDirectory\functions\Install-UnloadedModule.ps1
. $Script:ScriptDirectory\functions\Stop-PowerShell.ps1

Export-ModuleMember -Alias export, exa, colors, inumo, killps -Function 'Export-Variable', 'Invoke-Exa', 'Show-Colors', 'Install-UnloadedModule', 'Stop-PowerShell'

# Load Windows only functions.
# We're running on Windows if either:
#   - $IsWindows is true (PowerShell Core)
#   - $IsWindows does not exist (Windows PowerShell)
# Intentionally replicating the Windows check logic from `environment.ps1` here to avoid circular dependencies.
$Script:IsOsWindows = Get-Variable 'IsWindows' -Scope 'Global' -ErrorAction 'Ignore'
If ($Script:IsOsWindows -Ne $False) {
    . $Script:ScriptDirectory\functions\Invoke-XLaunch.ps1
    . $Script:ScriptDirectory\functions\Test-Administrator.ps1
    . $Script:ScriptDirectory\functions\New-Link.ps1

    Export-ModuleMember -Alias startx, isadmin, ln -Function 'Invoke-XLaunch', 'Test-Administrator', 'New-Link'
}