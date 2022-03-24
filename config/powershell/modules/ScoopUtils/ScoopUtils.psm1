# Only import the module once
if (Get-Module ScoopUtils) {
    return
}

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
        if ($null -eq (Get-Command -Name $package -ErrorAction SilentlyContinue)) {
            if ($PSCmdlet.ShouldProcess("Install Scoop Package: '$package'", $package , "Install-ScoopPackage")) {
                Write-Output "Installing '$package'..."
                scoop install $package

                if ($LastExitCode -eq 0) {
                    Write-Output "Installed '$package'!"

                    if ($null -eq (Get-Command -Name $Name -ErrorAction SilentlyContinue)) {
                        Write-Warning "'$package' not found on path. You may need to refresh your environment, or the package name may not match its executable."
                    }
                } else {
                    throw "Installation failed for '$package'!"
                }
            }
        } else {
            Write-Output "Package '$package' is already installed!"
        }
    }
}

function Read-ScoopFile {
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [String] $Path
    )

    if (-not (Test-Path -Path $Path)) {
        throw "Specified path does not exist: $Path"
    }

    $Scoopfile = Get-Content -Path $Path
    $Results = @()
    foreach ($Line in $Scoopfile) {
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
        if (-not ($LineComponents[1] -match "\(v:(?<version>.*)\)")) {
            throw "Invalid Entry: Malformed version - Entry: $Line"
        }
        $Version = $Matches['version']

        # Third component is the bucket the app is from, but may be missing for some apps
        $Bucket = $null
        if ($LineComponents.Length -eq 3) {
            if (-not ($LineComponents[2] -match "\[(?<bucket>.*)\]")) {
                throw "Invalid Entry: Malformed bucket - Entry: $Line"
            }
            $Bucket = $Matches['bucket']
        } else {
            Write-Warning "Missing bucket for entry: $Line"
        }

        # Add to the result set
        $Results +=  [PSCustomObject]@{
            App = $App
            Version = $Version
            Bucket = $Bucket
        }
    }

    return $Results
}

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
#endregion Exported Functions

Export-ModuleMember -Function 'Install-Scoop', 'Add-ScoopBucket', 'Install-ScoopPackage', 'Read-ScoopFile', 'Import-ScoopFile'
