function Test-Administrator {
    $Local:User = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $Local:User).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

Set-Alias isadmin Test-Administrator