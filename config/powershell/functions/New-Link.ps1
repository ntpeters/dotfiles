Function New-Link {
    <#
    .SYNOPSIS
    Creates a new link.
    Updates an existing link if one already exists or backs up a file if one exists at the target location.

    .DESCRIPTION
    The New-Link command creates a new link at the given location pointing to the specified path.
    This command is essentially a convenience wrapper around New-Item to simplify scripting link creation.

    The additional cases handled are:
    1. State:  Nothing exists at the link path
       Action: A new link is created
    2. State:  Link exists at link path, pointing to the target path
       Action: None
    3. State:  Link exists at link path, not pointing to the target path
       Action: Existing link is removed, and a new link is created
    4. State:  A non-link file exists at the link path
       Action: The file is backed up, and a new link is created

    .PARAMETER TargetPath
    The target path that the link will point to.

    .PARAMETER LinkPath
    The path where the link should be created.

    .PARAMETER LinkType
    The type of link to create. Default is 'SymbolicLink'
    Supported values are 'SymbolicLink' and 'Junction'.
    #>
    Param (
        [Parameter(Position=0, Mandatory=$True)]
        [ValidateScript({Test-Path -Path $_})]
        [string] $TargetPath,

        [Parameter(Position=1, Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string] $LinkPath,

        [Parameter(Position=2)]
        [ValidateSet("SymbolicLink", "Junction")]
        [string] $LinkType = "SymbolicLink"
    )

    $TargetItem = Get-Item -Path $TargetPath

    # Check if a file already exists at the link destination
    If (Test-Path -Path $LinkPath) {
        $LinkItem = Get-Item -Path $LinkPath

        # Check if the existing file is a link. Both junctions and symbolic links should be reparse points as well.
        $IsReparsePoint = [bool]($LinkItem.Attributes -band [IO.FileAttributes]::ReparsePoint)
        If ($IsReparsePoint -And ($LinkItem.LinkType -Eq $LinkType)) {
            # Normalize the target paths so they can be compared accurately
            $ExpectedTargetPath = Join-Path -Path $TargetItem.FullName -ChildPath $Null
            $CurrentTargetPath = Join-Path -Path $LinkItem.Target -ChildPath $Null

            # Check if the existing link has the same target that is being requested
            If ($CurrentTargetPath -Ne $ExpectedTargetPath) {
                # Remove links not pointing at the desired target
                Write-Warning "Removing stale link found at destination: '$($LinkItem.FullName)' -> '$($LinkItem.Target)'"
                Remove-Item -Path $LinkItem.FullName -Force
            } Else {
                # Link already exists with the desired target, so we're done!
                Write-Host -ForegroundColor Blue "Link Exists: '$($LinkItem.FullName)' -> '$($LinkItem.Target)'"
                Return
            }
        } Else {
            # Compose the file path for the backup file
            $LinkBackupName = "$($LinkItem.Name).old"
            If ($LinkItem -Is [System.IO.DirectoryInfo]) {
                $LinkBackupDirectory = $LinkItem.Parent.FullName
            } Else {
                $LinkBackupDirectory = $LinkItem.DirectoryName
            }
            $LinkBackupPath = Join-Path -Path $LinkBackupDirectory -ChildPath $LinkBackupName

            # Rename the file as a backup if one doesn't already exist
            Write-Warning "Backing up existing file found at destination: '$($LinkItem.FullName)' -> '${LinkBackupPath}'"
            If (Test-Path -Path $LinkBackupPath) {
                Throw "A backup already exists for this destination: '${LinkBackupPath}'"
            }
            Rename-Item -Path $LinkItem.FullName -NewName $LinkBackupName
        }
    }

    # Create the requested link
    $NewLink = New-Item -Path $LinkPath -ItemType $LinkType -Value $TargetItem.FullName
    If ($Null -Ne $NewLink) {
        Write-Host -ForegroundColor Green "Link Created: '$($NewLink.FullName)' -> '$($NewLink.Target)'"
    } Else {
        Write-Error "Failed to create link: '${LinkPath}' -> '${TargetPath}'"
    }
}

Set-Alias ln New-Link