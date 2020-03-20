Function Install-UnloadedModule {
    <#
    .SYNOPSIS
    Installs a module after ensuring it is unloaded from the current session.

    .PARAMETER Name
    The name of the module to install.
    #>
    Param (
        [Parameter(Position=0, Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    # Ensure the module is unloaded from the current session first, so it's not in use.
    Remove-Module -Name $Name -Force -ErrorAction 'Ignore'

    # Force install the module to replace an existing, local version.
    Install-Module -Name $Name -Force
}

# Roughly match the existing alias for Install-Module: inmo
Set-Alias inumo Install-UnloadedModule