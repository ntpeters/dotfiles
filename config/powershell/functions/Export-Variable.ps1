Function Export-Variable {
    <#
    .SYNOPSIS
    Sets an environment variable of the given name to the given value.
    If the value is omitted, the name is parsed as an expression of the form "Name=Value",
    and if successful the resulting name/value pair is used to set the environment variable.
    #>
    Param (
        [Parameter(Position=0)]
        [string]$Name,

        [Parameter(Position=1)]
        [string]$Value
    )

    If ([string]::IsNullOrEmpty($Name)) {
        Throw "Variable name or export expression is required."
    }

    If ([string]::IsNullOrEmpty($Value)) {
        $Name,$Value = $Name.Split('=', 2)
        If ([String]::IsNullOrEmpty($Value)) {
            Throw "Export expression must assign a value."
        }
    }

    # Set the environment variable for the current user.
    [Environment]::SetEnvironmentVariable($Name, $Value, [System.EnvironmentVariableTarget]::User)

    # Also make the variable available immediately in the current session.
    Invoke-Expression "`$Env:${Name}='${Value}'"
}

Set-Alias export Export-Variable
