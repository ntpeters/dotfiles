# PowerShell profile

# Set encoding
$OutputEncoding = [Text.Encoding]::UTF8
[Console]::OutputEncoding = $OutputEncoding
$PSDefaultParameterValues["Out-File:Encoding"] = "UTF8"
CHCP 65001 | Out-Null

# Init pshazz if available and not already initialized
If ((-Not $pshazz) -And ($Null -Ne $(Get-Command pshazz -ErrorAction 'Ignore'))) {
    pshazz init
}

# Set syntax colors
. "${Env:UserProfile}\.config\powershell\syntax-colors.ps1"

# Load environment variables
. "${Env:UserProfile}\.config\powershell\environment.ps1"

# Aliases
Invoke-Expression "$(thefuck --alias)"
Set-Alias fu fuck
Set-Alias pe path-extractor

# PSReadLine Settings
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadlineKeyHandler "Ctrl+Delete" KillWord
Set-PSReadlineKeyHandler "Ctrl+Backspace" BackwardKillWord
Set-PSReadlineKeyHandler "Ctrl+LeftArrow" BackwardWord
Set-PSReadlineKeyHandler "Ctrl+RightArrow" NextWord
Set-PSReadlineKeyHandler "Tab" MenuComplete

# Import custom functions
$Util = "${Env:UserProfile}\.config\powershell\ntpetersUtil.psm1"
If (Test-Path($Util)) {
    Import-Module "$Util"
}

# Chocolatey profile
$ChocolateyProfile = "$Env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
If (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

# Import utilities for OpenSSH on Windows.
# We're running on Windows if either:
#   - $IsWindows is true (PowerShell Core)
#   - $IsWindows does not exist (Windows PowerShell)
$Script:IsWindows = Get-Variable 'IsWindows' -Scope 'Global' -ErrorAction 'Ignore'
$OpenSshUtils = "${Env:UserProfile}\.config\powershell\openssh\OpenSSHUtils.psm1"
If (($Script:IsWindows -Eq $True) -And (Test-Path $OpenSshUtils)) {
    Import-Module "$OpenSshUtils"
}

# Source local PowerShell profile if one exists
$LocalPowerShellProfile = "${Env:UserProfile}\.config\powershell\local_profile.ps1"
If (Test-Path $LocalPowerShellProfile) {
    . $LocalPowerShellProfile
}
