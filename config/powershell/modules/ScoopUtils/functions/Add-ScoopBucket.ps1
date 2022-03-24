function Add-ScoopBucket {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [String[]] $Name
    )

    if ($PSCmdlet.ShouldProcess("Add Scoop Bucket: '$Name'", $Name , "Add-ScoopBucket")) {
        Write-Output "Adding Scoop bucket '$Name'..."
        scoop bucket add $Name
        if ($LastExitCode -ne 0) {
            throw "Adding bucket '$Name' failed!"
        }
    }
}