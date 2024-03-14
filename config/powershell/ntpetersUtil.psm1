# Only import the module once.
If (Get-Module ntpetersUtil) {
    return
}

$Script:ScriptDirectory = (Split-Path -Parent $MyInvocation.MyCommand.Definition)

. $Script:ScriptDirectory\functions\Export-Variable.ps1
. $Script:ScriptDirectory\functions\Show-Colors.ps1
. $Script:ScriptDirectory\functions\Install-UnloadedModule.ps1
. $Script:ScriptDirectory\functions\Stop-PowerShell.ps1
. $Script:ScriptDirectory\functions\Get-CommandTarget.ps1

Export-ModuleMember -Alias export, colors, inumo, killps, which -Function 'Export-Variable', 'Show-Colors', 'Install-UnloadedModule', 'Stop-PowerShell', 'Get-CommandTarget'

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

# TODO: Migration tab completions to something more supported so this shim isn't necessary
# Add a polyfill shim for TabExapansion on PowerShell >=7.4.
# Legacy TabExpansion is still used by pshazz tab completions.
. $Script:ScriptDirectory\functions\TabExpansionShim.ps1
Export-ModuleMember -Function TabExpansion2
