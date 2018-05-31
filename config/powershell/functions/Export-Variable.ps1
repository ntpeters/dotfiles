function Export-Variable($Name, $Value) {
    [Environment]::SetEnvironmentVariable($Name, $Value, [System.EnvironmentVariableTarget]::User)
}

Set-Alias export Export-Variable