Function Test-Variable {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Global", "Script", "Local")]
        [string]$Scope = $null
    )

    if ($null -ne $Scope) {
        $TestVariable = Get-Variable -Name $Name -Scope $Scope -ErrorAction 'Ignore'
    } else {
        $TestVariable = Get-Variable -Name $Name -ErrorAction 'Ignore'
    }

    return ($null -ne $TestVariable)
}