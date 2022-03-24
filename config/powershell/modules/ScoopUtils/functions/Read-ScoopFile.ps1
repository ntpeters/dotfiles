function Read-ScoopFile {
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [String] $Path
    )

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
            throw "Invalid Entry: Missing version - Entry: $Line"
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