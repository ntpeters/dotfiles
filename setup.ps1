# Setup script for Windows

# We're running on Windows if either:
#   - $IsWindows is true (PowerShell Core)
#   - $IsWindows does not exist (Windows PowerShell)
$Script:IsWindows = Get-Variable 'IsWindows' -Scope 'Global' -ErrorAction 'Ignore'
If ($Script:IsWindows -Eq $False) {
    Throw 'This script is intended for Windows only'
}

# Create PowerShell directory if it doesn't already exist
$Script:PowerShellHome = "${Env:UserProfile}\Documents\WindowsPowerShell"
If (-Not (Test-Path $Script:PowerShellHome)) {
    New-Item -Path $Script:PowerShellHome -ItemType 'Directory'
}

# Use the same directory for Windows PowerShell and PowerShell Core
$Script:PowerShellCoreHome = "${Env:UserProfile}\Documents\PowerShell"
If (-Not (Test-Path $Script:PowerShellCoreHome)) {
    New-Item -Path $Script:PowerShellCoreHome -ItemType Junction -Value "${Env:UserProfile}\Documents\WindowsPowerShell"
}

# Link PowerShell profile into place
$Script:PowerShellProfile = "${Script:PowerShellHome}\Microsoft.PowerShell_profile.ps1"
If (-Not (Test-Path $Script:PowerShellProfile)) {
    New-Item -Path $Script:PowerShellProfile -ItemType 'SymbolicLink' -Value "${Env:UserProfile}\.config\powershell\profile.ps1"
}

# Link pshazz directory into place
$Script:PshazzHome = "${Env:UserProfile}\pshazz"
If (-Not (Test-Path $Script:PshazzHome)) {
    New-Item -Path $Script:PshazzHome -ItemType 'Junction' -Value "${Env:UserProfile}\.config\pshazz"
}

# Set the pshazz theme
If ($(Get-Command pshazz -ErrorAction 'Ignore') -Ne $Null) {
    pshazz use steeef
}

# Import concfg settings
If ($(Get-Command concfg -ErrorAction 'Ignore') -Ne $Null) {
    concfg clean
    concfg import --non-interactive "${Env:UserProfile}\.config\concfg\settings.json"
}

# Link NeoVim config into place
$Script:NeoVimConfigDir= "${Env:UserProfile}\AppData\Local\nvim"
$Script:NeoVimConfig = "${$Script:NeoVimConfigDir}\init.vim"
If (-Not (Test-Path $Script:NeoVimConfig)) {
    New-Item -Path $Script:NeoVimConfig -ItemType 'SymbolicLink' -Value "${Env:UserProfile}\.config\nvim\init.vim"
}

# Link NeoVim GUI config into place
$Script:NeoVimGuiConfig = "${$Script:NeoVimConfigDir}\ginit.vim"
If (-Not (Test-Path $Script:NeoVimGuiConfig)) {
    New-Item -Path $Script:NeoVimGuiConfig -ItemType 'SymbolicLink' -Value "${Env:UserProfile}\.config\nvim\ginit.vim"
}

# Setup environment variables
. "${Env:UserProfile}\.config\powershell\environment.ps1"
