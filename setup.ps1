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

# Block execution of the script as admin.
# Some things like install apps from Scoop generally shouldn't be done as admin.
$Script:CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$Script:CurrentUserPrincipal = New-Object -TypeName Security.Principal.WindowsPrincipal -ArgumentList $Script:CurrentUser
if ($Script:CurrentUserPrincipal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Error 'This script should not be executed as an administrator. Elevation will be requested individually for commands that require it.'
    return
}

# Import utilities used by this script
Import-Module "${Env:UserProfile}\.config\powershell\ntpetersUtil.psm1"

# Load environment variables
. "${Env:UserProfile}\.config\powershell\environment.ps1"

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

    # TODO: Consider checking for existing contents in PowerShell dir (modules, etc) and moving them into the new unified dir

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
    if ($Script:MyDocumentsPath -ne "${Env:UserProfile}\Documents") {
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

    # Link gitignore as rgignore since ripgrep doesn't seem to handle core.excludesFile correctly on Windows
    New-Link -TargetPath "${Env:UserProfile}\.gitignore" -LinkPath "${Env:UserProfile}\.rgignore" -LinkType 'SymbolicLink'
}

function Initialize-PowerShell {
    [CmdletBinding(SupportsShouldProcess)]
    param ()

    # Import concfg settings
    if ($null -ne $(Get-Command concfg -ErrorAction 'Ignore')) {
        if ($PSCmdlet.ShouldProcess("Run 'concfg clean' to reset shell registry entries and shortcut properties", $null , $null)) {
            Write-Output "Running 'concfg clean' to reset shell registry entries and shortcut properties..."
            sudo concfg clean
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

    # Copy local configs into place
    $Script:LocalProfile = "${Env:UserProfile}\.config\powershell\local_profile.ps1"
    if (-not (Test-Path $Script:LocalProfile)) {
        Write-Output "Copying local PowerShell profile into place..."
        Copy-Item "${Env:UserProfile}\.config\powershell\local_profile.ps1.sample" $Script:LocalProfile
    } else {
        Write-Output "Local PowerShell profile already exists"
    }

    $Script:LocalEnvironment = "${Env:UserProfile}\.config\powershell\local_environment.ps1"
    if (-not (Test-Path $Script:LocalEnvironment)) {
        Write-Output "Copying local PowerShell environment into place..."
        Copy-Item "${Env:UserProfile}\.config\powershell\local_environment.ps1.sample" $Script:LocalEnvironment
    } else {
        Write-Output "Local PowerShell environment already exists"
    }

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
        Write-Output "Adding Defender exclusion for Visual Studio..."
        sudo Add-MpPreference -ExclusionPath $VsInstance.installationPath
    }

    if (-not ([String]::IsNullOrWhiteSpace($Env:CCACHE_DIR))) {
        Write-Output "Adding Defender exclusion for ccache cache directory..."
        sudo Add-MpPreference -ExclusionPath $Env:CCACHE_DIR
    }

    # Defender attack surface reduction rules can completely block delta from running
    if ($null -ne (Get-Command 'delta.exe' -ErrorAction 'Ignore')) {
        Write-Output "Adding Defender exclusion for delta..."
        sudo Add-MpPreference -ExclusionProcess 'delta.exe'
    }
}

function Install-OptionalFeatures {
    sudo "${Env:UserProfile}\.dotfiles\setup\scripts\Install-OpenSsh.ps1"
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
        Write-Output "Ensuring NPM is up to date..."
        npm update --global npm

        Write-Output "Installing NPM packages"
        npm install --global neovim
        if ($LastExitCode -ne 0) {
            Write-Error "Failed to install NPM package: 'neovim'"
        }
    } else {
        Write-Error "Failed to install NPM packages: NPM not found"
    }

    # Install pip packages
    if ($null -ne $(Get-Command pip -ErrorAction 'Ignore')) {
        Write-Output "Installing pip packages"
        pip install pynvim
        if ($LastExitCode -ne 0) {
            Write-Error "Failed to install pip package: 'pynvim'"
        }
    } else {
        Write-Error "Failed to install pip packages: pip not found"
    }

    # Install global cargo packages
    if ($null -ne $(Get-Command cargo -ErrorAction 'Ignore')) {
        Write-Output "Installing Cargo packages"

        if ($null -ne $(Get-Command viu -ErrorAction 'Ignore')) {
            cargo install viu
            if ($LastExitCode -ne 0) {
                Write-Error "Failed to install Cargo package: 'viu'"
            }
        } else {
            Write-Output "Cargo package 'viu' already installed"
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

    # Install Go packages
    if ($null -ne $(Get-Command go -ErrorAction 'Ignore')) {
        Write-Output "Installing Go packages..."

        if ($null -ne $(Get-Command path-extractor -ErrorAction 'Ignore')) {
            go install github.com/edi9999/path-extractor@latest
            if ($LastExitCode -ne 0) {
                Write-Error "Failed to install Go package: 'path-extractor'"
            }
        } else {
            Write-Output "Go package 'path-extractor' already installed"
        }
    } else {
        Write-Error "Failed to install Go packages: Go not found"
    }
}

function Set-WindowsSettings {
    # Set up the parameters for Set-ItemProperty
    # Possible values are:
    # 1: This PC
    # 2: Quick Access
    # 3: Downloads
    $sipParams = @{
        Path  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        Name  = 'LaunchTo'
        Value = 1 # Set the LaunchTo value for "This PC"
    }

  # Run Set-ItemProperty with the parameters we set above
  Set-ItemProperty @sipParams
}

function Set-RegistrySettings {
    [CmdletBinding(SupportsShouldProcess)]
    param ()

    # Enable long paths if needed
    [bool]$LongPathsEnabled = Get-ItemPropertyValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled'
    if (-not $LongPathsEnabled) {
        sudo Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value $true
        Write-Warning "NTFS Long Paths Enabled: A restart is required for this to take effect"
    } else {
        Write-Host -ForegroundColor Green "NTFS long paths already enabled"
    }

    # Disable Edge sidebar
    $EdgePolicies = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
    if (0 -ne $EdgePolicies.HubsSidebarEnabled) {
        sudo Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'HubsSidebarEnabled' -Value 0
        Write-Output "Microsoft Edge sidebar disabled"
    } else {
        Write-Host -ForegroundColor Green "Microsoft Edge sidebar already disabled"
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
