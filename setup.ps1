# Setup script for Windows
[CmdletBinding(DefaultParameterSetName = 'None')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = "Links")]
    [switch] $Links = $false,

    [Parameter(Mandatory = $true, ParameterSetName = "PowerShell")]
    [switch] $PowerShell = $false,

    [Parameter(Mandatory = $true, ParameterSetName = "DefenderExclusions")]
    [switch] $DefenderExclusions = $false,

    [Parameter(Mandatory = $true, ParameterSetName = "OptionalFeatures")]
    [switch] $OptionalFeatures = $false,

    [Parameter(Mandatory = $true, ParameterSetName = "Apps")]
    [switch] $Apps = $false,

    [Parameter(Mandatory = $true, ParameterSetName = "Settings")]
    [switch] $Settings = $false,

    [Parameter(Mandatory = $true, ParameterSetName = "Registry")]
    [switch] $Registry = $false
)

# Load Windows only functions.
# We're running on Windows if either:
#   - $IsWindows is true (PowerShell Core)
#   - $IsWindows does not exist (Windows PowerShell)
$Script:IsOsWindows = Get-Variable 'IsWindows' -Scope 'Global' -ErrorAction 'Ignore'
if ($Script:IsOsWindows -eq $false) {
    Throw 'This script is intended for Windows only'
}

# Honor user-specified ErrorAction if one was given, otherwise stop on error
if (-not ($MyInvocation.BoundParameters.ContainsKey('ErrorAction'))) {
    $ErrorActionPreference = "Stop"
}

# Import utilities used by this script
Import-Module "${Env:UserProfile}\.config\powershell\ntpetersUtil.psm1"

function Update-Links {
    # Create PowerShell directory if it doesn't already exist
    $Script:WindowsPowerShellHome = "${Env:UserProfile}\Documents\WindowsPowerShell"
    if (-not (Test-Path $Script:WindowsPowerShellHome)) {
        New-Item -Path $Script:WindowsPowerShellHome -ItemType 'Directory'
    }

    # Use the same directory for Windows PowerShell and PowerShell Core
    $Script:PowerShellCoreHome = "${Env:UserProfile}\Documents\PowerShell"
    New-Link -TargetPath $Script:WindowsPowerShellHome -LinkPath $Script:PowerShellCoreHome -LinkType 'Junction'

    # If the user's documents directory is not at '~/Documents', link the PowerShell directories into place there too.
    # This will be the case if 'Documents' is being backed up to OneDrive.
    $Script:MyDocumentsPath = [Environment]::GetFolderPath("MyDocuments")
    if ($Script:MyDocumentsPath -ne "${Env:UserProfile"}\Documents") {
        New-Link -TargetPath $Script:WindowsPowerShellHome -LinkPath "${Script:MyDocumentsPath}\WindowsPowerShell" -LinkType 'Junction'
        New-Link -TargetPath $Script:PowerShellCoreHome -LinkPath "${Script:MyDocumentsPath}\PowerShell" -LinkType 'Junction'
    }

    # Link PowerShell profile into place
    $Script:PowerShellProfile = "${Script:WindowsPowerShellHome}\Microsoft.PowerShell_profile.ps1"
    New-Link -TargetPath "${Env:UserProfile}\.config\powershell\profile.ps1" -LinkPath $Script:PowerShellProfile -LinkType 'SymbolicLink'

    # Link NeoVim config into place
    $Script:NeoVimConfigDir = "${Env:LocalAppData}\nvim"
    $Script:NeoVimConfig = "${Script:NeoVimConfigDir}\init.vim"
    New-Link -TargetPath "${Env:UserProfile}\.config\nvim\init.vim" -LinkPath $Script:NeoVimConfig -LinkType 'SymbolicLink'

    # Link NeoVim GUI config into place
    $Script:NeoVimGuiConfig = "${Script:NeoVimConfigDir}\ginit.vim"
    New-Link -TargetPath "${Env:UserProfile}\.config\nvim\ginit.vim" -LinkPath $Script:NeoVimGuiConfig -LinkType 'SymbolicLink'

    # Link VS Code config into place
    $Script:VisualStudioCodeConfig = "${Env:AppData}\Code\User\settings.json"
    New-Link -TargetPath "${Env:UserProfile}\.config\Code\User\settings.json" -LinkPath $Script:VisualStudioCodeConfig -LinkType 'SymbolicLink'

    # Link Windows Terminal config into place
    $Script:TeriminalConfigDotfile = "${Env:UserProfile}\.config\windowsTerminal\settings.json"
    $Script:TerminalConfigFormatString = "${Env:LocalAppData}\Packages\{0}\LocalState\settings.json"
    $Script:TerminalConfig = [string]::Format($Script:TerminalConfigFormatString, (Get-AppxPackage Microsoft.WindowsTerminal).PackageFamilyName)
    $Script:TerminalPreviewConfig = [string]::Format($Script:TerminalConfigFormatString, (Get-AppxPackage Microsoft.WindowsTerminalPreview).PackageFamilyName)
    New-Link -TargetPath $Script:TeriminalConfigDotfile -LinkPath $Script:TerminalConfig -LinkType 'SymbolicLink'
    New-Link -TargetPath $Script:TeriminalConfigDotfile -LinkPath $Script:TerminalPreviewConfig -LinkType 'SymbolicLink'
}

function Initialize-PowerShell {
    # Source the PowerShell profile
    . $Script:PowerShellProfile

    # Import concfg settings
    if ($null -ne $(Get-Command concfg -ErrorAction 'Ignore')) {
        concfg clean
        concfg import --non-interactive "${Env:UserProfile}\.config\concfg\settings.json"
    }

    # Kill other PowerShell instances before installing modules to ensure they aren't in use
    Stop-PowerShell -Type 'Current'

    # Required for PSReadLine
    Install-UnloadedModule -Name PowerShellGet

    # Use latest version instead of the one shipped in-box
    Install-UnloadedModule -Name PSReadLine
}

function Add-DefenderExclusions {
    $VsWhereCommand = "${Env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    $VsInstances = & $VsWhereCommand -prerelease -all -format json | ConvertFrom-Json
    Add-MpPreference -ExclusionPath $VsInstances.installationPath
    
    Add-MpPreference -ExclusionPath $Env:CCACHE_DIR
}

function Install-OptionalFeatures {
    Write-Warning "TODO: Install optional Windows features"
}

function Install-Apps {
    Write-Warning "TODO: Install apps and tools"
}

function Set-WindowsSettings {
    Write-Warning "TODO: Windows settings"
}

function Set-RegistrySettings {
    # Enable long paths if needed
    [bool]$LongPathsEnabled = Get-ItemPropertyValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled'
    if (-not $LongPathsEnabled) {
        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value $true
        Write-Warning "NTFS Long Paths Enabled: A restart is required for this to take effect"
    } else {
        Write-Host -ForegroundColor Green "NTFS long paths already enabled"
    }
}

$All = $PSCmdlet.ParameterSetName -eq 'None'
if ($Links -or $All) {
    Write-Output "Updating links..."
    Update-Links
}

if ($PowerShell -or $All) {
    Write-Output "Initializing PowerShell..."
    Initialize-PowerShell
}

if ($DefenderExclusions -or $All) {
    Write-Output "Adding Defender exclusions..."
    Add-DefenderExclusions
}

if ($OptionalFeatures -or $All) {
    Write-Output "Installing optional Windows features..."
    Install-OptionalFeatures
}

if ($Apps -or $All) {
    Write-Output "Installing apps..."
    Install-Apps
}

if ($Settings -or $All) {
    Write-Output "Configuring Windows settings..."
    Set-WindowsSettings
}

if ($Registry -or $All) {
    Write-Output "Configuring registry settings..."
    Set-RegistrySettings
}
