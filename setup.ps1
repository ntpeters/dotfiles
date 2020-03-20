# Setup script for Windows

# Load Windows only functions.
# We're running on Windows if either:
#   - $IsWindows is true (PowerShell Core)
#   - $IsWindows does not exist (Windows PowerShell)
$Script:IsOsWindows = Get-Variable 'IsWindows' -Scope 'Global' -ErrorAction 'Ignore'
If ($Script:IsOsWindows -Eq $False) {
    Throw 'This script is intended for Windows only'
}

# Honor user-specified ErrorAction if one was given, otherwise stop on error
If (-Not ($MyInvocation.BoundParameters.ContainsKey('ErrorAction'))) {
    $ErrorActionPreference = "Stop"
}

# Create PowerShell directory if it doesn't already exist
$Script:WindowsPowerShellHome = "${Env:UserProfile}\Documents\WindowsPowerShell"
If (-Not (Test-Path $Script:WindowsPowerShellHome)) {
    New-Item -Path $Script:WindowsPowerShellHome -ItemType 'Directory'
}

# Use the same directory for Windows PowerShell and PowerShell Core
$Script:PowerShellCoreHome = "${Env:UserProfile}\Documents\PowerShell"
New-Link -TargetPath $Script:WindowsPowerShellHome -LinkPath $Script:PowerShellCoreHome -LinkType 'Junction'

# If the user's documents directory is not at '~/Documents', link the PowerShell directories into place there too.
# This will be the case if 'Documents' is being backed up to OneDrive.
$Script:MyDocumentsPath = [Environment]::GetFolderPath("MyDocuments")
If ($Script:MyDocumentsPath -Ne "${Env:UserProfile"}\Documents") {
    New-Link -TargetPath $Script:WindowsPowerShellHome -LinkPath "${Script:MyDocumentsPath}\WindowsPowerShell" -LinkType 'Junction'
    New-Link -TargetPath $Script:PowerShellCoreHome -LinkPath "${Script:MyDocumentsPath}\PowerShell" -LinkType 'Junction'
}

# Link PowerShell profile into place
$Script:PowerShellProfile = "${Script:WindowsPowerShellHome}\Microsoft.PowerShell_profile.ps1"
New-Link -TargetPath "${Env:UserProfile}\.config\powershell\profile.ps1" -LinkPath $Script:PowerShellProfile -LinkType 'SymbolicLink'

# Source the PowerShell profile
. $Script:PowerShellProfile

# Import concfg settings
If ($Null -Ne $(Get-Command concfg -ErrorAction 'Ignore')) {
    concfg clean
    concfg import --non-interactive "${Env:UserProfile}\.config\concfg\settings.json"
}

# Link NeoVim config into place
$Script:NeoVimConfigDir= "${Env:LocalAppData}\nvim"
$Script:NeoVimConfig = "${Script:NeoVimConfigDir}\init.vim"
New-Link -TargetPath "${Env:UserProfile}\.config\nvim\init.vim" -LinkPath $Script:NeoVimConfig -LinkType 'SymbolicLink'

# Link NeoVim GUI config into place
$Script:NeoVimGuiConfig = "${Script:NeoVimConfigDir}\ginit.vim"
New-Link -TargetPath "${Env:UserProfile}\.config\nvim\ginit.vim" -LinkPath $Script:NeoVimGuiConfig -LinkType 'SymbolicLink'

# Link VS Code config into place
$Script:VisualStudioCodeConfig = "${Env:AppData}\Code\User\settings.json"
New-Link -TargetPath "${Env:UserProfile}\.config\Code\User\settings.json" -LinkPath $Script:VisualStudioCodeConfig -LinkType 'SymbolicLink'

# Kill other PowerShell instances before installing modules to ensure they aren't in use
Stop-PowerShell -Type 'Current'

# Required for PSReadLine
Install-UnloadedModule -Name PowerShellGet

# Use latest version instead of the one shipped in-box
Install-UnloadedModule -Name PSReadLine
