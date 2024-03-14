[CmdletBinding(SupportsShouldProcess)]
param()

$Script:CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$Script:CurrentUserPrincipal = New-Object -TypeName Security.Principal.WindowsPrincipal -ArgumentList $Script:CurrentUser
if (-not $Script:CurrentUserPrincipal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Error 'This script requires elevation to configure the Windows OpenSSH client'
    return
}

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
