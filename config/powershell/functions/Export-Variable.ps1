Function Export-Variable {
    <#
    .SYNOPSIS
    Sets an environment variable of the given name to the given value.
    If the value is omitted, the name is parsed as an expression of the form "Name=Value",
    and if successful the resulting name/value pair is used to set the environment variable.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(Position=0)]
        [string]$Name,

        [Parameter(Position=1)]
        [string]$Value,

        [switch]
        $Force
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

    # Only set the variable if the current value differs for the current user or process.
    # These checks are needed due to `SetEnvironmentVariable` automatically broadcasting a `WM_SETTINGCHANGE` message
    # and waiting for all top-level windows to respond.

    $userEnvironmentTarget = [System.EnvironmentVariableTarget]::User
    $processEnvironmentTarget = [System.EnvironmentVariableTarget]::Process
    $userEnvironmentTargetString = $userEnvironmentTarget.ToString().ToLower()
    $processEnvironmentTargetString = $processEnvironmentTarget.ToString().ToLower()
    $commonMessageFragmentFormat = "variable '$Name' for the current {0} with value of: '{1}'"
    $commonNotProcessMessageFragmentFormat = "export as the current value is equal to the provided value for $commonMessageFragmentFormat"

    # Set the environment variable for the current user.
    $shouldSetUserVariable = $Force -or ([Environment]::GetEnvironmentVariable($Name, $userEnvironmentTarget) -Ne $Value)
    if ($shouldSetUserVariable) {
        $shouldProcessCurrentUserMessage = "Exporting $commonMessageFragmentFormat" -f $userEnvironmentTargetString, $Value
        $verboseCurrentUserMessage = "Exported $commonMessageFragmentFormat" -f $userEnvironmentTargetString, $Value
    } else {
        $shouldProcessCurrentUserMessage = "Skipping $commonNotProcessMessageFragmentFormat" -f $userEnvironmentTargetString, $Value
        $verboseCurrentUserMessage = "Skipped $commonNotProcessMessageFragmentFormat" -f $userEnvironmentTargetString, $Value
    }
    if ($PSCmdlet.ShouldProcess($shouldProcessCurrentUserMessage, $Name ,"Export-Variable")) {
        if ($shouldSetUserVariable) {
            [Environment]::SetEnvironmentVariable($Name, $Value, $userEnvironmentTarget)
        }
        Write-Verbose $verboseCurrentUserMessage
    }

    # Also make the variable available immediately in the current session.
    $shouldSetProcessVariable = $Force -or ([Environment]::GetEnvironmentVariable($Name, $processEnvironmentTarget) -Ne $Value)
    if ($shouldSetProcessVariable) {
        $shouldProcessCurrentProcessMessage = "Exporting $commonMessageFragmentFormat" -f $processEnvironmentTargetString, $Value
        $verboseCurrentProcessMessage = "Exported $commonMessageFragmentFormat" -f $processEnvironmentTargetString, $Value
    } else {
        $shouldProcessCurrentProcessMessage = "Skipping $commonNotProcessMessageFragmentFormat" -f $processEnvironmentTargetString, $Value
        $verboseCurrentProcessMessage = "Skipped $commonNotProcessMessageFragmentFormat" -f $processEnvironmentTargetString, $Value
    }
    if ($PSCmdlet.ShouldProcess($shouldProcessCurrentProcessMessage, $Name ,"Export-Variable")) {
        if ($shouldSetProcessVariable) {
            [Environment]::SetEnvironmentVariable($Name, $Value, $processEnvironmentTarget)
        }
        Write-Verbose $verboseCurrentProcessMessage
    }
}

Set-Alias export Export-Variable

# TODO: add function to refresh environment variables
# adapt the one from choco: https://github.com/chocolatey/choco/blob/stable/src/chocolatey.resources/helpers/functions/Update-SessionEnvironment.ps1

# TODO: fix handling of expandable values on Windows
# relevant dotnet bug: https://github.com/dotnet/runtime/issues/1442
# choco workarounds as references:
# https://github.com/chocolatey/choco/blob/stable/src/chocolatey.resources/helpers/functions/Get-EnvironmentVariable.ps1
# https://github.com/chocolatey/choco/blob/stable/src/chocolatey.resources/helpers/functions/Set-EnvironmentVariable.ps1