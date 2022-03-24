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

                if (($LastExitCode -ne 0) -and ($null -eq (Get-Command -Name $Name -ErrorAction SilentlyContinue))) {
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