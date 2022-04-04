# ScoopUtils Module
# Module providing helpers for interacting with Scoop

# Only import the module once
if (Get-Module ScoopUtils) {
    return
}

#region Internal
# Custom data type for describing a Scoop package entry
class ScoopPackage
{
    [ValidateNotNullOrEmpty()][string]$App
    [string]$Version
    [ValidateNotNullOrEmpty()][string]$Bucket

    [string] ToString() {
        return $this.ToString($true)
    }

    [string] ToString([switch] $IncludeVersions) {
        if ((-not $IncludeVersions) -or [string]::IsNullOrWhiteSpace($this.Version)) {
            return "{0} [{1}]" -f $this.App, $this.Bucket
        } else {
            return "{0} (v:{1}) [{2}]" -f $this.App, $this.Version, $this.Bucket
        }
    }
}
#endregion Internal

#region Exported Functions
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

function Install-ScoopPackage {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [String[]] $Name
    )

    foreach ($package in $Name) {
        $app,$version = $package -split '@'
        if ($null -eq (Get-Command -Name $app -ErrorAction SilentlyContinue)) {
            if ($PSCmdlet.ShouldProcess("Install Scoop Package: '$package'", $package , "Install-ScoopPackage")) {
                Write-Output "Installing '$package'..."
                scoop install $package

                if ($LastExitCode -eq 0) {
                    Write-Output "Installed '$package'!"

                    if ($null -eq (Get-Command -Name $app -ErrorAction SilentlyContinue)) {
                        Write-Warning "'$app' not found on path. You may need to refresh your environment, or the package name may not match its executable."
                    }
                } else {
                    throw "Installation failed for '$package'!"
                }
            }
        } else {
            Write-Output "Package '$app' is already installed!"
        }
    }
}

function ConvertFrom-ScoopExportList {
    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [string[]] $ScoopExportList,
        [switch] $IncludeVersions
    )

    # Explicit begin, process, and end blocks are required to properly accept multi-line pipeline input
    begin {}

    process {
        $Results = @()
        foreach ($Line in $ScoopExportList) {
            # Ignore empty and comment lines
            if ([string]::IsNullOrWhiteSpace($Line) -or ($Line.Trim()[0] -eq '#')) {
                continue
            }

            # Splitting the line on spaces should produce 3 components: app, version, bucket
            $LineComponents = $Line -split ' '
            if ($LineComponents.Length -notin 2..3) {
                throw "Invalid Entry: Unexpected number of components ($($LineComponents.Length) instead of 2 or 3) - Entry: $Line"
            }

            # First component is the app name
            $App = $LineComponents[0]

            # Second component is the version
            if ($IncludeVersions) {
                if (-not ($LineComponents[1] -match "\(v:(?<version>.*)\)")) {
                    throw "Invalid Entry: Malformed version - Entry: $Line"
                }
                $Version = $Matches['version']
            }

            # Third component is the bucket the app is from, but may be missing for some apps
            $Bucket = $null
            # if ($LineComponents.Length -eq $LineComponentsRange[-1]) {
                if (-not ($LineComponents[-1] -match "\[(?<bucket>.*)\]")) {
                    throw "Invalid Entry: Malformed bucket - Entry: $Line"
                } else {
                    $Bucket = $Matches['bucket']
                }
            # } else {
            #     Write-Warning "Missing bucket for entry: $Line"
            # }

            # Add to the result set
            $Results +=  [ScoopPackage]@{
                App = $App
                Version = $Version
                Bucket = $Bucket
            }
        }

        return $Results
    }

    end {}
}

function ConvertTo-ScoopExportList {
    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ScoopPackage[]] $Packages,
        [switch] $IncludeVersions
    )

    # Explicit begin, process, and end blocks are required to properly accept multi-line pipeline input
    begin {}

    process {
        foreach ($Package in $Packages) {
            Write-Output $Package.ToString($IncludeVersions)
        }
    }

    end {}
}

function Read-ScoopFile {
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [String] $Path,
        [switch] $IncludeVersions
    )

    if (-not (Test-Path -Path $Path)) {
        throw "Specified path does not exist: $Path"
    }

    $Scoopfile = Get-Content -Path $Path
    return ConvertFrom-ScoopExportList -ScoopExportList $Scoopfile -IncludeVersions:$IncludeVersions
}

function Import-ScoopFile {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [String] $Path,
        [switch] $UseVersions
    )

    Write-Output "Reading scoopfile..."
    $Packages = Read-ScoopFile -Path $Path -IncludeVersions:$UseVersions
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
        if ($UseVersions -and (-not [string]::IsNullOrWhiteSpace($Package.Version))) {
            $App = [string]::Format("{0}@{1}", $Package.App, $Package.Version)
        }

        Install-ScoopPackage -Name $App
    }
}

function Export-ScoopFile {
    [CmdletBinding()]
    param (
        [String] $Path,
        [switch] $IncludeVersions
    )

    if (Test-Path -Path $Path) {
        throw "File already exists at provided path: $Path"
    }

    $ScoopExportList = scoop export
    $ScoopAppsFilteredVersions = ConvertFrom-ScoopExportList -ScoopExportList $ScoopExportList -IncludeVersions:$IncludeVersions
    $ScoopExportListFilteredVersions = ConvertTo-ScoopExportList -Packages $ScoopAppsFilteredVersions -IncludeVersions:$IncludeVersions
    $ScoopExportListFilteredVersions | Out-File -FilePath $Path
}
#endregion Exported Functions

Export-ModuleMember -Function 'Install-Scoop', 'Add-ScoopBucket', 'Install-ScoopPackage', 'Read-ScoopFile', 'Import-ScoopFile', 'Export-ScoopFile', 'ConvertFrom-ScoopExportList', 'ConvertTo-ScoopExportList'
