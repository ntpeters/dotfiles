Function Remove-ModuleVariable {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Module
    )

    foreach ($Scope in 'Global', 'Script', 'Local') {
        if ((Test-Variable -Name $Name -Scope $Scope) -and (Test-ModuleVariable -Name $Name -Module $Module)) {
            Remove-Variable -Name $Name -Scope $Scope -Force
        }
    }
}