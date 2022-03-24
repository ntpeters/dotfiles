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