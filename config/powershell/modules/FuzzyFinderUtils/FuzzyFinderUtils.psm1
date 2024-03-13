<#
.SYNOPSIS
Provides helpers for selecting paths and editing files from searches by fd or rg.

.DESCRIPTION
Helpers are provided for selecting paths (Select-PathFromFd and Select-PathFromRg) from fd and rg results, and
for editing files at paths (Edit-PathFromFd and Edit-PathFromRg) from fd and rg results.

For editing, the environment variables EDITOR and VISUAL are used to determine the terminal or visual editor to open the file in.
To open a file for editing directly to the line number of a result (ie. for rg), the environment varialbes EDITOR_LINE_NUMBER_FORMAT
and VISUAL_LINE_NUMBER_FORMAT are used. The values of these variables is dependent on the syntax of the specified editor for opening
directly to a given line number.
#>

# Only import the module once
if (Get-Module FuzzyFinderUtils) {
    return
}

#region Internal Functions
<#
.SYNOPSIS
Splits a path containing a line number into path and line number components.

.DESCRIPTION
Given a path ending with a line number, the path component is returned without the line number
unless the LineNumber parameter is set. If LineNumber is set, then only the line number component
is returned.
If the path does not contain a line number the path itself will be returned, and if LineNumber is
set then null is returned.

The path with line number is epxected to be of the format:
this/is/a/path.txt:NN

.PARAMETER Path
The path ending with a line number to split.

.PARAMETER LineNumber
When set only the line number component of the given path is returned, or null if no line number is found.
#>
function Split-PathWithLineNumber(
    [Parameter(Position=0, Mandatory=$true)]
    [string]
    $Path,
    [Parameter(Mandatory=$false)]
    [switch]
    $LineNumber = $false
)
{
    if ([string]::IsNullOrWhiteSpace($Path))
    {
        throw "No path specified."
    }

    $matchedPath = $Path | Select-String -Pattern ":\d+$"
    if ($null -ne $matchedPath)
    {
        $pathSegment = $matchedPath.Line.Substring(0, $matchedPath.Matches.Index)
        $lineNumberSegment = $matchedPath.Matches.Value.Substring(1)
    }
    else
    {
        $pathSegment = $Path
        $lineNumberSegment = $null
    }

    if ($LineNumber)
    {
        return $lineNumberSegment
    }
    else
    {
        return $pathSegment
    }
}

<#
.SYNOPSIS
Joins a path with a line number.

.DESCRIPTION
Combines the given path and line number into a single path ending with a line number of the format:
this/is/a/path.txt:NN

.PARAMETER Path
The path component to join.

.PARAMETER LineNumber
The line number component to join.
#>
function Join-PathWithLineNumber(
    [Parameter(Position=0, Mandatory=$true)]
    [string]
    $Path,
    [Parameter(Position=1, Mandatory=$true)]
    [string]
    $LineNumber
)
{
    if ([string]::IsNullOrWhiteSpace($Path))
    {
        throw "No path specified."
    }

    return "${Path}:${LineNumber}"
}

<#
.SYNOPSIS
Tests whether the file or directory pointed to by the path exists.

.DESCRIPTION
Determines if the file or directory specified by the path component of the given path ending with a line
number exists.

The path with line number is epxected to be of the format:
this/is/a/path.txt:NN

.PARAMETER Path
The path with line number to test the existance of.
#>
function Test-PathWithLineNumber(
    [Parameter(Position=0, Mandatory=$true)]
    [string]
    $Path
)
{
    if ([string]::IsNullOrWhiteSpace($Path))
    {
        throw "No path specified."
    }

    $pathWithoutLineNumber = Split-PathWithLineNumber -Path $Path
    return Test-Path -Path $pathWithoutLineNumber
}

<#
.SYNOPSIS
Invokes the given command and prompts to select a path from the command output.

.DESCRIPTION
Executes the specified command and displays the results for user selection.
Paths are extracted from the selected result, and if only a single path is found
it is returned. If more than one path is found, then invalid paths are removed
and the user is prompted again to select one of the remaining valid paths.

.PARAMETER Command
The command to execute.

.PARAMETER ResultIncludesLineNumbers
Whether the paths output from the command are expected to include line numbers.
#>
function Select-PathFromCommandResult(
    [Parameter(Position=0, Mandatory=$true)]
    [string]
    $Command,
    [Parameter(Mandatory=$false)]
    [switch]
    $ResultIncludesLineNumbers = $false
)
{
    if ([string]::IsNullOrWhiteSpace($Command))
    {
        throw "No command specified."
    }

    if ($null -eq $(Get-Command 'fzf' -ErrorAction 'Ignore'))
    {
        throw "FZF not found on path."
    }

    if ($null -eq $(Get-Command 'path-extractor' -ErrorAction 'Ignore'))
    {
        throw "path-extractor not found on path."
    }

    Write-Debug "Invoking Command: $Command"
    $results = Invoke-Expression -Command $Command
    $commandExitCode = $LASTEXITCODE
    if ($commandExitCode -ne 0)
    {
        Write-Debug "Command completed with a non-zero exit code: ExitCode='$commandExitCode'; Command='$Command'"
        return $null
    }

    $resultCount = @($results).Count
    Write-Debug "Command Result Count: $resultCount"
    Write-Debug "To output command result values, use '-Debug' and '-Verbose' together."
    if (($DebugPreference -ne 'SilentlyContinue') -and ($VerbosePreference -ne 'SilentlyContinue'))
    {
        Write-Debug "Command Results:"
        foreach ($result in $results)
        {
            Write-Debug $result
        }
    }

    if ([string]::IsNullOrWhiteSpace($results))
    {
        Write-Debug "No results from command invocation. Command='$Command'"
        return $null
    }

    # Use bat for FZF previews if available, otherwise fallback to PS Get-Content
    $fzfPreviewCommand = "pwsh -Command Get-Content '{1}'"
    if ($null -ne $(Get-Command 'bat' -ErrorAction 'Ignore'))
    {
        # bat options:
        # --number: display line numbers
        # --color=always: enable syntax highlighting
        # --highlight-line: highlight the line where the result was found (if applicable)
        $fzfPreviewCommand = 'bat --number --color=always {1}'
        if ($ResultIncludesLineNumbers)
        {
            $fzfPreviewCommand += ' --highlight-line {2}'
        }
    }
    else
    {
        Write-Debug "'bat' not found on path, defaulting to PowerShell's Get-Content for fzf preview"
    }

    # When run with the debug flag, don't run FZF in fullscreen mode to preserve all debug output
    $fzfHeightFlag = $null
    if ($DebugPreference -ne 'SilentlyContinue')
    {
        Write-Debug "Running FZF with reduced height to preserve debug output"
        $fzfHeightFlag = "--height=50%"
    }

    if ($results -is [array])
    {
        Write-Debug "Command result is an array, prompting user to select entry"

        # Prompt to select an entry if the result is an array
        # fzf options:
        # --ansi: parse ANSI color codes from the input to display colors
        # --delimiter ':': delimit the path from the line number to allow individually addressing them for the preview window
        # --preview-window: set the preview window to display at the top and scroll down to the line containing the result
        # --preview: the command to use for the preview window
        $results = $results.ForEach({ $_.Trim() })
        $selectedResult = $results | fzf --ansi --delimiter ':' $fzfHeightFlag --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' --preview $fzfPreviewCommand
    }
    elseif ($results -is [string])
    {
        Write-Debug "Command result is a string, no user selection needed"

        # If the result is a string, strip ANSI color codes and use it
        $selectedResult = $results -replace '\x1b\[[0-9;]*m',''
    }
    else
    {
        # This probably shouldn't happen?
        throw "Command invocation result is of an unhandled type. ResultType='$($results.GetType().Name)'; Command='$Command'"
    }

    Write-Debug "Selected Command Result: $selectedResult"
    Write-Debug "Extracting paths from command result"
    $extractedPaths = $selectedResult | path-extractor
    Write-Debug "Extracted Paths: $extractedPaths"
    if ([string]::IsNullOrWhiteSpace($extractedPaths))
    {
        Write-Debug "No paths detected in command invocation result. Command='$Command'"
        return $null
    }

    # Handle when the selected result contains more than one path by discarding any invalid paths
    if ($extractedPaths -is [array])
    {
        Write-Debug "More than one path extracted from command result, filtering out invalid paths"

        $validExtractedPaths = $extractedPaths.Where({ (-not [string]::IsNullOrWhiteSpace($_)) -and (Test-PathWithLineNumber -Path $_.Trim()) })
        Write-Debug "Valid Extracted Paths: $validExtractedPaths"

        if ([string]::IsNullOrWhiteSpace($validExtractedPaths))
        {
            Write-Debug "No valid paths detected in command invocation result. Command='$Command'"
            return $null
        }

        # Handle if the remaining valid paths are still a list
        if ($validExtractedPaths -is [array] -or $validExtractedPaths -is [System.Collections.IList])
        {
            if ($validExtractedPaths.Count -eq 0)
            {
                Write-Debug "No valid paths detected in command invocation result. Command='$Command'"
                return $null
            }
            elseif ($validExtractedPaths.Count -eq 1)
            {
                Write-Debug "Single path extracted from command result, no user selection needed"

                $validExtractedPath = $validExtractedPaths[0]
            }
            else
            {
                Write-Debug "More than one valid extracted paths remain, prompting user to select an entry"

                # Prompt to select an entry if the result is an array
                $validExtractedPath = $validExtractedPaths | fzf --ansi
            }
        }
        elseif ($validExtractedPaths -is [string])
        {
            Write-Debug "Single valid extracted path remains, no user selection needed"

            $validExtractedPath = $validExtractedPaths
        }
        else
        {
            # This probably shouldn't happen?
            throw "Valid extracted paths result is of an unhandled type. ResultType='$($validExtractedPaths.GetType().Name)'; Command='$Command'"
        }
    }
    elseif (($extractedPaths -is [string]) -and (Test-PathWithLineNumber -Path $extractedPaths.Trim()))
    {
        Write-Debug "Single path extracted from command result, no user selection needed"

        $validExtractedPath = $extractedPaths
    }
    else
    {
        Write-Debug "No valid paths detected in command invocation result. Command='$Command'"
        return $null
    }

    # Get the absolute path
    Write-Debug "Expanding selected path to an absolute path"
    $pathToExpand = Split-PathWithLineNumber -Path $validExtractedPath.Trim()
    Write-Debug "Path To Expand: $pathToExpand"
    $absolutePath = Convert-Path -Path $pathToExpand
    Write-Debug "Absolute Path: $absolutePath"

    # Join path with line number if needed
    if ($ResultIncludesLineNumbers)
    {
        $lineNumber = Split-PathWithLineNumber -LineNumber -Path $validExtractedPath
        Write-Debug "Line Number From Path: $lineNumber"
        $absolutePath = Join-PathWithLineNumber -Path $absolutePath -LineNumber $lineNumber
        Write-Debug "Absolute Path With Line Number: $absolutePath"
    }

    return $absolutePath
}

<#
.SYNOPSIS
Gets the configured file editor.

.DESCRIPTION
Gets the editor to use for editing files. If one is provided it is returned, otherwise
the value of the EDITOR environment variable is returned if defined and Visual is not set.
If Visual is set or EDITOR is undefined, then the value of the VISUAL environment variable
is returned.

.PARAMETER Editor
Editor to use instead of the values defined by the EDITOR or VISUAL environment variables.

.PARAMETER Visual
When set, the value of VISUAL will be chosen over EDITOR environment variables.
#>
function Get-EditorOrDefault(
    [Parameter(Position=0, Mandatory=$false)]
    [string]
    $Editor = $null,
    [Parameter(Mandatory=$false)]
    [switch]
    $Visual = $false
)
{
    if (-Not [string]::IsNullOrWhiteSpace($Editor))
    {
        Write-Debug "Using user-provided editor: $Editor"
        return $Editor
    }

    if ((-Not $Visual) -and (-Not [string]::IsNullOrWhiteSpace($Env:Editor)))
    {
        Write-Debug "Using editor from EDITOR environment variable: $Env:Editor"
        return $Env:Editor
    }

    if (-Not [string]::IsNullOrWhiteSpace($Env:Visual))
    {
        Write-Debug "Using visual editor from VISUAL environment variable: $Env:Visual"
        return $Env:Visual
    }

    throw "No editor specified, and environment variables EDITOR and VISUAL are undefined."
}

<#
.SYNOPSIS
Gets the format string for opening a file to a specific line in an editor.

.DESCRIPTION
Gets the format string for opening a file to a specific line in the editor to use for editing files.
If one is provided it is returned, otherwise the value of the EDITOR_LINE_NUMBER_FORMAT environment variable
is returned if defined and Visual is not set.
If Visual is set or EDITOR_LINE_NUMBER_FORMAT is undefined, then the value of the VISUAL_LINE_NUMBER_FORMAT
environment variable is returned.

.PARAMETER EditorLineNumberFormat
Editor to use instead of the values defined by the EDITOR_LINE_NUMBER_FORMAT or VISUAL_LINE_NUMBER_FORMAT environment variables.

.PARAMETER Visual
When set, the value of VISUAL will be chosen over EDITOR environment variables.
#>
function Get-EditorLineNumberFormatOrDefault(
    [Parameter(Position=0, Mandatory=$false)]
    [string]
    $EditorLineNumberFormat = $null,
    [Parameter(Mandatory=$false)]
    [switch]
    $Visual = $false
)
{
    if (-Not [string]::IsNullOrWhiteSpace($EditorLineNumberFormat))
    {
        Write-Debug "Using user-provided editor line number format: $EditorLineNumberFormat"
        return $EditorLineNumberFormat
    }

    if ((-Not $Visual) -and (-Not [string]::IsNullOrWhiteSpace($Env:Editor_Line_Number_Format)))
    {
        Write-Debug "Using editor line number format from EDITOR_LINE_NUMBER_FORMAT environment variable: $Env:Editor_Line_Number_Format"
        return $Env:Editor_Line_Number_Format
    }

    if (-Not [string]::IsNullOrWhiteSpace($Env:Visual_Line_Number_Format))
    {
        Write-Debug "Using visual editor line number format from VISUAL_LINE_NUMBER_FORMAT environment variable: $Env:Visual_Line_Number_Format"
        return $Env:Visual_Line_Number_Format
    }

    Write-Debug "No editor line number format specified, and environment varialbes EDITOR_LINE_NUMBER_FORMAT and VISUAL_LINE_NUMBER_FORMAT are undefined."
    return $null
}
#endregion Internal Functions

#region Exported Functions
<#
.SYNOPSIS
Executes fd with the given query, and prompts to select a path from the results.

.DESCRIPTION
Runs fd with the provided query and displays the results to allow selecting a path.

.PARAMETER Query
Query to provide to fd.

.PARAMETER Args
Arguments to pass to fd. When not specified explicitly, captures all unmatched arguments to this command.
#>
function Select-PathFromFd(
    [Parameter(Position=0, Mandatory=$true)]
    [string]
    $Query,
    [Parameter(Position=1, ValueFromRemainingArguments)]
    [string]
    $Args
)
{
    if ([string]::IsNullOrWhiteSpace($Query))
    {
        throw "No query specified."
    }

    if ($null -eq $(Get-Command 'fd' -ErrorAction 'Ignore'))
    {
        throw "fd not found on path."
    }

    if (-not [string]::IsNullOrWhiteSpace($Args))
    {
        Write-Debug "Additional args to fd: $Args"
    }

    # fd options:
    # --color always: preservce colors when piping the result
    # --path-separator '/': path-extractor doesn't support Windows path separators (ie. \)
    return Select-PathFromCommandResult -Command "fd --color always --path-separator '/' $Args $Query"
}

<#
.SYNOPSIS
Executes rg with the given query, and prompts to select a path from the results.

.DESCRIPTION
Runs rg with the provided query and displays the results to allow selecting a path.

.PARAMETER Query
Query to provide to rg.

.PARAMETER Args
Arguments to pass to rg. When not specified explicitly, captures all unmatched arguments to this command.
#>
function Select-PathFromRg(
    [Parameter(Position=0, Mandatory=$true)]
    [string]
    $Query,
    [Parameter(Position=1, ValueFromRemainingArguments)]
    [string]
    $Args,
    [Parameter(Mandatory=$false)]
    [switch]
    $IncludeLineNumber = $false
)
{
    if ([string]::IsNullOrWhiteSpace($Query))
    {
        throw "No query specified."
    }

    if ($null -eq $(Get-Command 'rg' -ErrorAction 'Ignore'))
    {
        throw "rg not found on path."
    }

    if (-not [string]::IsNullOrWhiteSpace($Args))
    {
        Write-Debug "Additional args to rg: $Args"
    }

    # rg options:
    # --color always: preserve colors when piping the result
    # --line-number: show the line where the result was found, needed when opening a file directly to a specific line
    # --path-separator=/: path-extractor doesn't support Windows path separators (ie. \)
    $selectedPath = Select-PathFromCommandResult -Command "rg --color always --line-number --path-separator=/ $Args $Query" -ResultIncludesLineNumbers:$IncludeLineNumber
    if ([string]::IsNullOrWhiteSpace($selectedPath))
    {
        return $null
    }

    if ($IncludeLineNumber)
    {
        return $selectedPath
    }
    else
    {
        return Split-PathWithLineNumber -Path $selectedPath
    }
}

<#
.SYNOPSIS
Executes fd with the given query, prompts to select a path from the results, and opens the selected file for editing.

.DESCRIPTION
Runs fd with the provided query and displays the results to allow selecting a path.
The selected path is opened in either the specified editor, or the value from either
the EDITOR or VISUAL environment variables, if defined.

.PARAMETER Query
Query to provide to fd.

.PARAMETER Args
Arguments to pass to fd. When not specified explicitly, captures all unmatched arguments to this command.

.PARAMETER Editor
Editor to use instead of the values defined by the EDITOR or VISUAL environment variables.

.PARAMETER Visual
When set, the value of VISUAL will be chosen over EDITOR environment variables.
#>
function Edit-PathFromFd(
    [Parameter(Position=0, Mandatory=$true)]
    [string]
    $Query,
    [Parameter(Position=1, ValueFromRemainingArguments)]
    [string]
    $Args,
    [Parameter(Mandatory=$false)]
    [string]
    $Editor = $null,
    [Parameter(Mandatory=$false)]
    [switch]
    $Visual = $false
)
{
    $editorToInvoke = Get-EditorOrDefault -Editor $Editor -Visual:$Visual
    $editPath = Select-PathFromFd -Query $Query -Args $Args
    if ([string]::IsNullOrWhiteSpace($editPath))
    {
        Write-Debug "No path selected for editing."
        return;
    }

    Invoke-Expression -Command "$editorToInvoke $editPath"
}

<#
.SYNOPSIS
Executes rg with the given query, prompts to select a path from the results, and opens the selected file for editing.

.DESCRIPTION
Runs rg with the provided query and displays the results to allow selecting a path.
The selected path is opened in an editor selected in the following priority order:
- Specified by the EditorLineNumberFormat parameter
- Defined by the EDITOR_LINE_NUMBER_FORMAT environment variable (if Visual is not set)
- Defined by the VISUAL_LINE_NUMBER_FORMAT environment variable (if Visual is set or EDITOR_LINE_NUMBER_FORMAT is undefined)
- Specified by the Editor parameter
- Defined by the EDITOR environment varialbe (if Visual is not set)
- Defined by the VISUAL environment varialbe (if Visual is set or EDITOR is undefined)

.PARAMETER Query
Query to provide to rg.

.PARAMETER Args
Arguments to pass to rg. When not specified explicitly, captures all unmatched arguments to this command.

.PARAMETER Editor
Editor to use instead of the values defined by the EDITOR or VISUAL environment variables.

.PARAMETER EditorLineNumberFormat
Editor line number format to use instead of the values defined by the EDITOR_LINE_NUMBER_FORMAT or
VISUAL_LINE_NUMBER_FORMAT environment variables.

.PARAMETER Visual
When set, the value of VISUAL will be chosen over EDITOR environment variables.
#>
function Edit-PathFromRg(
    [Parameter(Position=0, Mandatory=$true)]
    [string]
    $Query,
    [Parameter(Position=1, ValueFromRemainingArguments)]
    [string]
    $Args,
    [Parameter(Mandatory=$false)]
    [string]
    $Editor = $null,
    [Parameter(Mandatory=$false)]
    [string]
    $EditorLineNumberFormat = $null,
    [Parameter(Mandatory=$false)]
    [switch]
    $Visual = $false
)
{
    # Try to get an editor line number format, and fallback to just an editor if not found
    $editorLineNumberFormatString = Get-EditorLineNumberFormatOrDefault -EditorLineNumberFormat $EditorLineNumberFormat -Visual:$Visual
    if ([string]::IsNullOrWhiteSpace($editorLineNumberFormatString))
    {
        Write-Debug "No editor line number format found, checking for editor to default to."
        $editorToInvoke = Get-EditorOrDefault -Editor $Editor -Visual:$Visual

        $editPath = Select-PathFromRg -Query $Query -Args $Args
        if ([string]::IsNullOrWhiteSpace($editPath))
        {
            Write-Debug "No path selected for editing."
            return;
        }
        else
        {
            Write-Debug "Selected Path: $editPath"
        }

        $editorCommand = "$editorToInvoke $editPath"
    }
    else
    {
        Write-Debug "Editor Line Number Format String: $editorLineNumberFormatString"

        $editPath = Select-PathFromRg -IncludeLineNumber -Query $Query -Args $Args
        Write-Debug "Selected Path: $editPath"
        if ([string]::IsNullOrWhiteSpace($editPath))
        {
            Write-Debug "No path selected for editing."
            return;
        }
        else
        {
            Write-Debug "Selected Path: $editPath"
        }

        $editPathSegment = Split-PathWithLineNumber -Path $editPath
        $editLineNumberSegment = Split-PathWithLineNumber -LineNumber -Path $editPath
        $editorCommand = [string]::Format($editorLineNumberFormatString, $editPathSegment, $editLineNumberSegment)
    }

    Write-Debug "Editor Command: $editorCommand"
    Invoke-Expression -Command $editorCommand
}
#endregion Exported Functions

#region Dependency Checks
# Check for the presense of application dependencies, and print helpful warnings for any that aren't found
if ($null -eq $(Get-Command 'fzf' -ErrorAction 'Ignore'))
{
    Write-Warning "fzf not found on path, some functionality may not work (get it here: https://github.com/junegunn/fzf)"
}

if ($null -eq $(Get-Command 'fd' -ErrorAction 'Ignore'))
{
    Write-Warning "fd not found on path, some functionality may not work (get it here: https://github.com/sharkdp/fd)"
}

if ($null -eq $(Get-Command 'rg' -ErrorAction 'Ignore'))
{
    Write-Warning "rg not found on path, some functionality may not work (get it here: https://github.com/BurntSushi/ripgrep)"
}

if ($null -eq $(Get-Command 'path-extractor' -ErrorAction 'Ignore'))
{
    Write-Warning "path-extractor not found on path, some functionality may not work (get it here: https://github.com/edi9999/path-extractor)"
}

if ($null -eq $(Get-Command 'bat' -ErrorAction 'Ignore'))
{
    Write-Warning "bat not found on path, only basic file previews will be supported (get it here: https://github.com/sharkdp/bat)"
}
#endregion Dependency Checks

Set-Alias -Name fdp -Value Select-PathFromFd
Set-Alias -Name rgp -Value Select-PathFromRg
Set-Alias -Name fdo -Value Edit-PathFromFd
Set-Alias -Name rgo -Value Edit-PathFromRg

Export-ModuleMember -Alias fdp, rgp, fdo, rgo -Function 'Select-PathFromFd', 'Select-PathFromRg', 'Edit-PathFromFd', 'Edit-PathFromRg'