# Restrict this function to Windows only, since it's not meant to work elsewhere.
# We're running on Windows if either:
#   - $IsWindows is true (PowerShell Core)
#   - $IsWindows does not exist (Windows PowerShell)
$Script:IsWindows = Get-Variable 'IsWindows' -Scope 'Global' -ErrorAction 'Ignore'
If ($Script:IsWindows -Eq $False) {
    Throw 'The Invoke-XLaunch function is intended for Windows only.'
}

Function Invoke-XLaunch {
    <#
    .SYNOPSIS
    Launches an X server on Windows via xlaunch.
    Optionally accepts a path to the configuration file to run xlaunch with.
    If no path is provided, the environment variable 'XLaunchConfig' will be checked for a path.
    If the evironment variable is not set, the default path will be used instead.
    #>
    Param (
        [Parameter(Position=0)]
        [string]$ConfigPath
    )

    If ([string]::IsNullOrEmpty($ConfigPath)) {
        $ConfigPath = [Environment]::GetEnvironmentVariable("XLaunchConfig", [System.EnvironmentVariableTarget]::User)
        If ([string]::IsNullOrEmpty($ConfigPath)) {
            $ConfigPath = "${Env:UserProfile}\.config\xlaunch\config.xlaunch"
        }
    }

    If (-Not (Test-Path $ConfigPath)) {
        Write-Warning "No XLaunch configuration not found at path: ${ConfigPath}"
        Write-Warning "Executing XLaunch with no configuration."
        xlaunch
    }

    xlaunch -run "${ConfigPath}"
}

Set-Alias startx Invoke-XLaunch
