# PowerShell profile

# Set encoding
$OutputEncoding = [Text.Encoding]::UTF8
[Console]::OutputEncoding = $OutputEncoding
CHCP 65001 | Out-Null

# Init pshazz if available and not already initialized
If ((-Not $pshazz) -And ($(Get-Command pshazz -ErrorAction 'Ignore') -Ne $Null)) {
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

function Invoke-LaunchX {
    xlaunch -run "${Env:UserProfile}\.config\xlaunch\config.xlaunch"
}

Set-Alias startx Invoke-LaunchX

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
