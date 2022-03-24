# Setup script for Windows
[CmdletBinding(DefaultParameterSetName = 'None', SupportsShouldProcess)]
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

# Honor user-specified ErrorAction if one was given, otherwise stop on error
if (-not ($MyInvocation.BoundParameters.ContainsKey('ErrorAction'))) {
    $ErrorActionPreference = "Stop"
}

# Load Windows only functions.
# We're running on Windows if either:
#   - $IsWindows is true (PowerShell Core)
#   - $IsWindows does not exist (Windows PowerShell)
$Script:IsOsWindows = Get-Variable 'IsWindows' -Scope 'Global' -ErrorAction 'Ignore'
if ($Script:IsOsWindows -eq $false) {
    Write-Error 'This script is intended for Windows only'
    return
}

$Script:CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$Script:CurrentUserPrincipal = New-Object -TypeName Security.Principal.WindowsPrincipal -ArgumentList $Script:CurrentUser
if (-not $Script:CurrentUserPrincipal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Error 'This script requires elevation to configure the Windows OpenSSH client'
    return
}

# Import utilities used by this script
Import-Module "${Env:UserProfile}\.config\powershell\ntpetersUtil.psm1"

#region Helpers
function Get-AppxPackageFamilyName {
    param(
        [string] $Name
    )

    # The Appx module only works in Windows PowerShell, so fallback to powershell if we're running in PS Core
    if ($PSEdition -eq 'Desktop') {
        return (Get-AppxPackage -Name $Name).PackageFamilyName
    } else {
        return powershell.exe -NoProfile -Command "(Get-AppxPackage -Name $Name).PackageFamilyName"
    }
}

function Install-OpenSsh {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $SshClientCapability = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Client*'
    if ($null -eq $SshClientCapability) {
        throw "Windows Capability 'OpenSSH.Client' not found!"
    }

    if ($SshClientCapability.State -ne 'Installed') {
        if ($PSCmdlet.ShouldProcess("Install Windows Capability: 'OpenSSH.Client'", "OpenSSH.Client" , "Add-WindowsCapability")) {
            Write-Output "Installing OpenSSH.Client..."
            Add-WindowsCapability -Online -Name 'OpenSSH.Client~~~~0.0.1.0'
        }
    } else {
        Write-Output "OpenSSH.Client already installed!"
    }

    $SshAgentServiceInfo = Get-Service -Name 'ssh-agent'
    if ($SshAgentServiceInfo.StartType -ne 'Manual') {
        if ($PSCmdlet.ShouldProcess("Set service 'ssh-agent' startup type to manual", "ssh-agent" , "Set-Service")) {
            Set-Service -Name 'ssh-agent' -StartupType Manual
        }
    } else {
        Write-Output "Service 'ssh-agent' startup type is already manual"
    }

    if ($SshAgentServiceInfo.Status -ne 'Running') {
        if ($PSCmdlet.ShouldProcess("Start service 'ssh-agent'", $null , $null)) {
            Start-Service -Name 'ssh-agent'
        }
    } else {
        Write-Output "Service 'ssh-agent' is already running"
    }
}

function Set-ScoopSettings {
    if ($Null -ne $(Get-Command scoop -ErrorAction 'Ignore')) {
        Write-Host "Creating scoop alias 'outdated'..."
        scoop alias add outdated "scoop update --quiet; scoop status" "Lists all packages that have available updates"
    }
    else {
        Write-Warning "Failed to create scoop aliases: scoop is not installed"
    }
}
#endregion Helpers

function Update-Links {
    [CmdletBinding(SupportsShouldProcess)]
    param ()

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
    $Script:TerminalPackageFamilyName = Get-AppxPackageFamilyName -Name 'Microsoft.WindowsTerminal'
    if (-not [string]::IsNullOrWhiteSpace($Script:TerminalPackageFamilyName)) {
        $Script:TerminalConfig = [string]::Format($Script:TerminalConfigFormatString, $Script:TerminalPackageFamilyName)
        New-Link -TargetPath $Script:TeriminalConfigDotfile -LinkPath $Script:TerminalConfig -LinkType 'SymbolicLink'
    } else {
        Write-Warning "Skipped linking Windows Terminal profile: Windows Terminal is not installed"
    }

    # Link Windows Terminal Preview config into place
    $Script:TerminalPreviewPackageFamilyName = Get-AppxPackageFamilyName -Name 'Microsoft.WindowsTerminalPreview'
    if (-not [string]::IsNullOrWhiteSpace($Script:TerminalPreviewPackageFamilyName)) {
        $Script:TerminalPreviewConfig = [string]::Format($Script:TerminalConfigFormatString, $Script:TerminalPreviewPackageFamilyName)
        New-Link -TargetPath $Script:TeriminalConfigDotfile -LinkPath $Script:TerminalPreviewConfig -LinkType 'SymbolicLink'
    } else {
        Write-Warning "Skipped linking Windows Terminal Preview profile: Windows Terminal Preview is not installed"
    }
}

function Initialize-PowerShell {
    [CmdletBinding(SupportsShouldProcess)]
    param ()

    # Import concfg settings
    if ($null -ne $(Get-Command concfg -ErrorAction 'Ignore')) {
        if ($PSCmdlet.ShouldProcess("Run 'concfg clean' to reset shell registry entries and shortcut properties", $null , $null)) {
            Write-Output "Running 'concfg clean' to reset shell registry entries and shortcut properties..."
            concfg clean
        }

        Write-Output "Importing concgf settings..."
        concfg import --non-interactive "${Env:UserProfile}\.config\concfg\settings.json"
    }

    # Kill other PowerShell instances before installing modules to ensure they aren't in use
    Write-Output "Stopping other PowerShell instances..."
    Stop-PowerShell -Type 'Current'

    # Required for PSReadLine
    Write-Output "Installing PowerShellGet..."
    Install-UnloadedModule -Name PowerShellGet

    # Use latest version instead of the one shipped in-box
    Write-Output "Installing PSReadLine..."
    Install-UnloadedModule -Name PSReadLine

    # Use latest version instead of the one shipped in-box
    Write-Output "Installing PSFzf..."
    Install-UnloadedModule -Name PSFzf

    # Source the PowerShell profile
    Write-Output "Sourcing PowerShell profile: $Profile"
    . $Profile
}

function Add-DefenderExclusions {
    [CmdletBinding(SupportsShouldProcess)]
    param ()

    $VsWhereCommand = "${Env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    $VsInstances = & $VsWhereCommand -prerelease -all -format json | ConvertFrom-Json
    foreach ($VsInstance in $VsInstances) {
        Add-MpPreference -ExclusionPath $VsInstance.installationPath
    }

    Add-MpPreference -ExclusionPath $Env:CCACHE_DIR
}

function Install-OptionalFeatures {
    Install-OpenSsh
}

function Install-Apps {
    [CmdletBinding(SupportsShouldProcess)]
    param ()

    # Install Scoop packages
    Import-Module "${Env:UserProfile}\.config\powershell\modules\ScoopUtils\ScoopUtils.psm1"
    if ($null -eq $(Get-Command scoop -ErrorAction 'Ignore')) {
        Write-Output "Scoop not found, installing now..."
        Install-Scooop
    }
    Set-ScoopSettings
    Write-Output "Installing Scoop packages"
    Import-ScoopFile -Path "${Env:UserProfile}\.dotfiles\setup\packages\scoopfile"

    # TODO: Write helpers for installing from these package managers
    # Install global npm packages
    if ($null -ne $(Get-Command npm -ErrorAction 'Ignore')) {
        Write-Output "Installing NPM packages"
        npm install --global neovim
        if ($LastExitCode -ne 0) {
            Write-Error "Failed to install NPM package: 'neovim'"
        }
    } else {
        Write-Error "Failed to install NPM packages: NPM not found"
    }

    # Install global cargo packages
    if ($null -ne $(Get-Command cargo -ErrorAction 'Ignore')) {
        Write-Output "Installing Cargo packages"
        cargo install viu
        if ($LastExitCode -ne 0) {
            Write-Error "Failed to install Cargo package: 'viu'"
        }
    } else {
        Write-Error "Failed to install Cargo packages: Cargo not found"
    }

    # Install WinGet packages
    if ($null -ne $(Get-Command winget -ErrorAction 'Ignore')) {
        Write-Output "Installing WinGet packages"

        if ($null -eq $(Get-Command wt -ErrorAction 'Ignore')) {
            winget install Microsoft.WindowsTerminal.Preview
            if ($LastExitCode -ne 0) {
                Write-Error "Failed to install WinGet package: 'Microsoft.WindowsTerminal.Preview'"
            }
        } else {
            Write-Output "Windows Terminal already installed"
        }
    } else {
        Write-Error "Failed to install WinGet packages: WinGet not found"
    }
}

function Set-WindowsSettings {
    Write-Warning "TODO: Windows settings"
}

function Set-RegistrySettings {
    [CmdletBinding(SupportsShouldProcess)]
    param ()

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

if ($Registry -or $All) {
    Write-Output "Configuring registry settings..."
    Set-RegistrySettings
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
