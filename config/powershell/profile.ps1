
# Set encoding
$OutputEncoding = [Text.Encoding]::UTF8
[Console]::OutputEncoding = $OutputEncoding
CHCP 65001 | Out-Null

# Init pshazz if available
If ($(Get-Command pshazz -ErrorAction 'Ignore') -Ne $Null) {
    pshazz init
}

# Set syntax colors
. "${Env:UserProfile}\.config\powershell\syntax-colors.ps1"

function Export-Variable($Name, $Value) {
    [Environment]::SetEnvironmentVariable($Name, $Value, [System.EnvironmentVariableTarget]::User)
}

# Configure the prompt for cmd. See 'prompt /?' for info on accepted format codes.
Export-Variable 'Prompt' "${Env:UserName}`$Sat`$S${Env:ComputerName}`$Sin`$S`$P`$_`$`$`$S"

Set-Variable -Name "PYTHONIOENCODING" -Value "utf-8"
$Env:PYTHONIOENCODING="utf-8"

Export-Variable 'ConEmuANSI' 'ON'

Invoke-Expression "$(thefuck --alias)"
Set-Alias fu fuck

# Chocolatey profile
$ChocolateyProfile = "$Env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

function Show-Colors( ) {
    $Local:Colors = [Enum]::GetValues([ConsoleColor])
    $Local:MaxLength = ($Local:Colors | ForEach-Object { "$_ ".Length } | Measure-Object -Maximum).Maximum
    ForEach($Color in $Local:Colors) {
        Write-Host (" {0,2} {1,$Local:MaxLength} " -f [int]$Color,$Color) -NoNewline
        Write-Host "$Color" -Foreground $Color
    }
}

function Test-Administrator {
    $Local:User = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $Local:User).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function Invoke-Exa {
    & bash.exe -c "exa $args"
}

Set-Alias exa Invoke-Exa

# Source local PowerShell profile if one exists
$LocalPowerShellProfile = "${Env:UserProfile}\Documents\WindowsPowerShell\local_profile.ps1"
If (Test-Path $LocalPowerShellProfile) {
    . $LocalPowerShellProfile
}
