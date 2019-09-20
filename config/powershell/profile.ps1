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

# Source local PowerShell profile if one exists
$LocalPowerShellProfile = "${Env:UserProfile}\Documents\WindowsPowerShell\local_profile.ps1"
If (Test-Path $LocalPowerShellProfile) {
    . $LocalPowerShellProfile
}
