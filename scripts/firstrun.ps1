<#
.SYNOPSIS
Sets up the minimum requirements to get dotfiles ready and execute the full setup script.
#>
[CmdletBinding(SupportsShouldProcess)]
param()

# Honor user-specified ErrorAction if one was given, otherwise stop on error
# Note: Requires CmdletBinding annotation at the script level
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

function Install-Scoop {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($null -eq (Get-Command -Name 'scoop' -ErrorAction SilentlyContinue)) {
        if ($PSCmdlet.ShouldProcess("Install Scoop", "Scoop" , "Install-Scoop")) {
            Write-Output "Installing Scoop..."
            Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
            Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
        }
    } else {
        Write-Output "Scoop already installed!"
    }
}

function Install-ScoopPackage {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [String[]] $Name
    )

    foreach ($package in $Name) {
        if ($null -eq (Get-Command -Name $package -ErrorAction SilentlyContinue)) {
            if ($PSCmdlet.ShouldProcess("Install Scoop Package: '$package'", $package , "Install-ScoopPackage")) {
                Write-Output "Installing '$package'..."
                scoop install $package

                if ($null -eq (Get-Command -Name $Name -ErrorAction SilentlyContinue)) {
                    Write-Output "Installed '$package'!"
                } else {
                    throw "Installation failed for '$package'!"
                }
            }
        } else {
            Write-Output "Package '$package' is already installed!"
        }
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

function Install-Updot {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $UpdotDir = Join-Path -Path "${Env:UserProfile}" -ChildPath ".updot"
    $UpdotPath = Join-Path -Path $UpdotDir -ChildPath "updot.py"
    if (-not (Test-Path -Path $UpdotPath)) {
        if ($PSCmdlet.ShouldProcess("Install Updot", "Updot" , "Install-Updot")) {
            Write-Output "Installing Updot..."
            git clone "https://github.com/ntpeters/updot.git" "$UpdotDir"
        }
    } else {
        Write-Output "Updot already installed"
    }
}

Install-Scoop
Install-ScoopPackage -Name 'git', 'python', 'pwsh'
Install-OpenSsh
Install-Updot
