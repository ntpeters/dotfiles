# Setup script for Windows

# We're running on Windows if either:
#   - $IsWindows is true (PowerShell Core)
#   - $IsWindows does not exist (Windows PowerShell)
$Script:IsOsWindows = Get-Variable 'IsWindows' -Scope 'Global' -ErrorAction 'Ignore'
If ($Script:IsOsWindows -Eq $False) {
    Throw 'This script is intended for Windows only'
}

# Create PowerShell directory if it doesn't already exist
$Script:WindowsPowerShellHome = "${Env:UserProfile}\Documents\WindowsPowerShell"
If (-Not (Test-Path $Script:WindowsPowerShellHome)) {
    New-Item -Path $Script:WindowsPowerShellHome -ItemType 'Directory'
}

# Use the same directory for Windows PowerShell and PowerShell Core
$Script:PowerShellCoreHome = "${Env:UserProfile}\Documents\PowerShell"
If (-Not (Test-Path $Script:PowerShellCoreHome)) {
    New-Item -Path $Script:PowerShellCoreHome -ItemType Junction -Value "${Env:UserProfile}\Documents\PowerShell"
}

# If the user's documents directory is not at '~/Documents', link the PowerShell directories into place there too.
# This will be the case if 'Documents' is being backed up to OneDrive.
$Script:MyDocumentsPath = [Environment]::GetFolderPath("MyDocuments")
If ($Script:MyDocumentsPath -Ne "${Env:UserProfile"}\Documents") {
    New-Item -Path $Script:WindowsPowerShellHome -ItemType Junction -Value "${Script:MyDocumentsPath}\WindowsPowerShell"
    New-Item -Path $Script:PowerShellCoreHome -ItemType Junction -Value "${Script:MyDocumentsPath}\PowerShell"
}

# Link PowerShell profile into place
$Script:PowerShellProfile = "${Script:WindowsPowerShellHome}\Microsoft.PowerShell_profile.ps1"
If (-Not (Test-Path $Script:PowerShellProfile)) {
    New-Item -Path $Script:PowerShellProfile -ItemType 'SymbolicLink' -Value "${Env:UserProfile}\.config\powershell\profile.ps1"
}

# Source the PowerShell profile
. $Script:PowerShellProfile

# Import concfg settings
If ($Null -Ne $(Get-Command concfg -ErrorAction 'Ignore')) {
    concfg clean
    concfg import --non-interactive "${Env:UserProfile}\.config\concfg\settings.json"
}

# Link NeoVim config into place
$Script:NeoVimConfigDir= "${Env:UserProfile}\AppData\Local\nvim"
$Script:NeoVimConfig = "${Script:NeoVimConfigDir}\init.vim"
If (-Not (Test-Path $Script:NeoVimConfig)) {
    New-Item -Path $Script:NeoVimConfig -ItemType 'SymbolicLink' -Value "${Env:UserProfile}\.config\nvim\init.vim"
}

# Link NeoVim GUI config into place
$Script:NeoVimGuiConfig = "${$Script:NeoVimConfigDir}\ginit.vim"
If (-Not (Test-Path $Script:NeoVimGuiConfig)) {
    New-Item -Path $Script:NeoVimGuiConfig -ItemType 'SymbolicLink' -Value "${Env:UserProfile}\.config\nvim\ginit.vim"
}
