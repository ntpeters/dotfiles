<#
.SYNOPSIS
    Defines variables for determinining the current host operating system.

.DESCRIPTION
    When imported into Windows PowerShell the following ReadOnly variables are defined
    to match PowerShell Core: `IsWindows`, `IsMacOS`, `IsLinux`.

    When imported into any PowerShell the ReadOnly variable `IsWSL` is defined.

    Ideally these variables would also have the AllScope option set to truly match PowerShell Core,
    but unfortunately that option is currently broken for modules:
    https://github.com/PowerShell/PowerShell/issues/6378
#>

# Source our functions
$Script:ModuleFunctions = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) -ChildPath 'functions'
. (Join-Path -Path $Script:ModuleFunctions -ChildPath 'New-ModuleVariable.ps1')
. (Join-Path -Path $Script:ModuleFunctions -ChildPath 'Test-ModuleVariable.ps1')
. (Join-Path -Path $Script:ModuleFunctions -ChildPath 'Test-Variable.ps1')
. (Join-Path -Path $Script:ModuleFunctions -ChildPath 'Remove-ModuleVariable.ps1')

# Replicate the `IsWindows`, `IsMacOS, and `IsLinux` environment variables for consistency with PowerShell Core in Windows PowerShell.
if ($PSEdition -eq 'Desktop') {
    New-ModuleVariable -Name 'IsWindows' -Value $true -ReadOnly -Description "When true, denotes that the current session is running on Windows."
    New-ModuleVariable -Name 'IsMacOS' -Value $false -ReadOnly -Description "When true, denotes that the current session is running on macOS."
    New-ModuleVariable -Name 'IsLinux' -Value $false -ReadOnly -Description "When true, denotes that the current session is running on Linux."
}

# Add an `IsWSL` variable as a counterpart to the other OS check variables.
# We're running on WSL if either /proc/version or /proc/sys/kernel/osrelease contain 'Microsoft' or 'WSL'.
# This should always be the case according to this comment:
# https://github.com/microsoft/WSL/issues/423#issuecomment-221627364
# Check is case-insensitive to support WSL2, which switched to lowercase 'microsoft'.
[bool]$Script:WSLCheck = Select-String -LiteralPath '/proc/version', '/proc/sys/kernel/osrelease' -Pattern 'Microsoft|WSL' -Quiet -ErrorAction 'Ignore'
New-ModuleVariable -Name 'IsWSL' -Value $WSLCheck -ReadOnly -Description "When true, denotes that the current session is running under WSL."

$ExecutionContext.SessionState.Module.OnRemove += {
    $Script:ModuleName = [io.path]::GetFileNameWithoutExtension($Script:MyInvocation.MyCommand.Name)
    Remove-ModuleVariable -Name 'IsWindows' -Module $ModuleName
    Remove-ModuleVariable -Name 'IsMacOS' -Module $ModuleName
    Remove-ModuleVariable -Name 'IsLinux' -Module $ModuleName
    Remove-ModuleVariable -Name 'IsWSL' -Module $ModuleName
}
