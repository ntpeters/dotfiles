$Local:ScriptDirectory = (Split-Path -Parent $MyInvocation.MyCommand.Definition)
. $Local:ScriptDirectory\Add-ScoopBucket.ps1
. $Local:ScriptDirectory\Install-ScoopPackage.ps1
. $Local:ScriptDirectory\Read-ScoopFile.ps1

function Import-ScoopFile {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [String] $Path,
        [switch] $UseVersions
    )

    Write-Output "Reading scoopfile..."
    $Packages = Read-ScoopFile -Path $Path
    Write-Output "Found $($Packages.Length) apps to install"

    $Buckets = $Packages | Select-Object -ExpandProperty 'Bucket' -Unique
    foreach ($Bucket in $Buckets) {
        # Add the bucket for the app if it's not in the main bucket
        if ((-not [string]::IsNullOrWhiteSpace($Bucket)) -and ($Bucket -ne 'main')) {
            Add-ScoopBucket -Name $Bucket
        }
    }

    foreach ($Package in $Packages) {
        # Issue a warning if no bucket is defined for an app
        if ($null -eq $Package.Bucket) {
            Write-Warning "Missing bucket definition for '$($Package.App)', installation may fail"
        }

        # Include specific version if requested
        $App = $Package.App
        if ($UseVersions) {
            $App = [string]::Format("{0}@{1}", $Package.App, $Package.Version)
        }

        Install-ScoopPackage -Name $App
    }
}