Function Test-ModuleVariable {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Module
    )

    $TestVariable = Get-Variable -Name $Name -ErrorAction 'Ignore'
    return ($Module -eq $TestVariable.ModuleName)
}