# PowerShell profile

# Set encoding
# Specifically not using Text.Encoding.UTF8 here, since that encoding includes a BOM which breaks terminal apps (especially when piping).
# This is the same encoding set by default for PowerShell Core, but it's set explicitly here for somewhat consistent behavior in Windows PowerShell (except for piping, which always seems to have a BOM added regardless of encoding).
$OutputEncoding = [Text.UTF8Encoding]::new()
$InputEncoding = [Text.UTF8Encoding]::new()
[Console]::OutputEncoding = $OutputEncoding
[Console]::InputEncoding = $InputEncoding
$PSDefaultParameterValues["Out-File:Encoding"] = "UTF8"
CHCP 65001 | Out-Null

# Init pshazz if available and not already initialized
if ($null -eq $(Get-Command pshazz -ErrorAction 'Ignore')) {
    # TODO: set a default prompt
} elseif (-not $pshazz) {
    pshazz init
}

# Set syntax colors
. "${Env:UserProfile}\.config\powershell\syntax-colors.ps1"

# Load environment variables
. "${Env:UserProfile}\.config\powershell\environment.ps1"

# Aliases
if ($null -ne $(Get-Command thefuck -ErrorAction 'Ignore')) {
    Invoke-Expression "$(thefuck --alias)"
    Set-Alias fu fuck
}

if ($null -ne $(Get-Command path-extractor -ErrorAction 'Ignore')) {
    Set-Alias pe path-extractor
}

# PSReadLine Settings
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadlineKeyHandler "Ctrl+Delete" KillWord
Set-PSReadlineKeyHandler "Ctrl+Backspace" BackwardKillWord
Set-PSReadlineKeyHandler "Ctrl+LeftArrow" BackwardWord
Set-PSReadlineKeyHandler "Ctrl+RightArrow" NextWord
Set-PSReadlineKeyHandler "Tab" MenuComplete

if (($null -ne (Get-Module -Name PSFzf -ListAvailable -ErrorAction Ignore)) -and ($null -ne (Get-Command fzf -ErrorAction Ignore))) {
    # Import-Module PSFzf

    # Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r' -EnableFd -FileSystemCommand 'fd . --color always --type directory {0}'
    # -FileSystemCommandDefaultArgs '--type file' -FileSystemCommandDirectoryOnlyArgs '--type directory' -FileSystemCommandColorArgs '--color always'
}

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
$OpenSshUtils = "${Env:UserProfile}\.config\powershell\openssh\OpenSSHUtils.psm1"
If (($Global:IsWindows -Eq $True) -And (Test-Path $OpenSshUtils)) {
    Import-Module "$OpenSshUtils"
}

#Import fuzzy finder utilities
if ($null -eq (Get-Module 'FuzzyFinderUtils')) {
    Import-Module 'FuzzyFinderUtils'
}

# Source local PowerShell profile if one exists.
If (Test-Path $Global:LocalProfile) {
    . $Global:LocalProfile
}