Function New-ModuleVariable {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [Object]$Value,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [switch]$ReadOnly = $false
    )

    # Only allow the ReadOnly option, as this is the only one that makes sense for exporting from a module.
    # Technically the AllScope option is desirable to support as well, but it's behavior is currently broken for modules:
    # https://github.com/PowerShell/PowerShell/issues/6378
    $Option = 'None'
    if ($ReadOnly) {
        $Option = 'ReadOnly'
    }

    New-Variable -Name $Name -Value $Value -Option $Option -Description $Description -Scope 'Script'
    Export-ModuleMember -Variable $Name
}