if (Get-Module ntpetersUtil) { return }

$scriptDirectory = (Split-Path -parent $MyInvocation.MyCommand.Definition)

. $scriptDirectory\functions\Export-Variable.ps1
. $scriptDirectory\functions\Invoke-Exa.ps1
. $scriptDirectory\functions\Show-Colors.ps1
. $scriptDirectory\functions\Test-Administrator.ps1

Export-ModuleMember -Alias export, exa, colors, isadmin -Function 'Export-Variable', 'Invoke-Exa', 'Show-Colors', 'Test-Administrator'