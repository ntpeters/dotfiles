# Dynamic command-existence highlighting (zsh-style), layered on top of PSReadLine.
#
# PSReadLine colors tokens by *kind* only: every command-position token gets the "Command" color
# (white-on-blue, set in syntax-colors.ps1) regardless of whether the command actually resolves.
# This script adds the missing piece - the zsh-syntax-highlighting behavior where an unknown command
# shows up red - by repainting command tokens after each keystroke:
#
#   * unknown / unresolved                                  -> red text
#   * alias                                                 -> green text
#   * cmdlet / function / application / script / all others -> left as-is (white-on-blue)
#
# Only the override cases (unknown, alias) touch the screen, so valid commands - the common case -
# cost nothing to draw and never flicker; a partially typed name shows red and snaps to blue the
# moment it resolves, exactly like zsh.
#
# Performance: a `Get-Command` on a name that does NOT resolve triggers PowerShell's module auto-load
# discovery and costs ~300ms - fatal on a per-keystroke path (every partial command is a "miss"). So,
# like zsh hashing $PATH, we resolve against prebuilt name indexes instead: a HashSet of alias names
# (-> green) and a HashSet of every other known command name (-> skip). Per keystroke is then an O(1)
# lookup. The index is seeded instantly from this session's already-loaded commands and completed in a
# background runspace (all auto-loadable cmdlets/functions + every executable on PATH, ~1s). Until that
# finishes, unknown names are NOT flagged red - so nothing flickers red incorrectly during warm-up.
#
# Mechanism: bind a key handler to every printable character (plus Backspace/Delete) that performs the
# normal edit, then walks the parsed command line and recolors the on-screen cells of any command token
# needing an override, via the classic Windows console buffer APIs (GetBufferContents/SetBufferContents)
# - which exist only on the Windows ConsoleHost, so the guards below disable the feature anywhere else.
#
# The ~180ms of one-time setup (buffer-API probe + binding ~193 keys) is deferred off the profile-load
# critical path: a one-shot prompt wrapper runs it on the first prompt render. Run
# Initialize-CommandHighlighting to (re)apply on demand.

# Requires PSReadLine 2+ (GetBufferState, color dictionary).
$PSReadlineModule = Get-Module -Name PSReadline
if ($null -eq $PSReadlineModule -or $PSReadlineModule.Version.Major -lt 2) {
    return
}

# Interactive console sessions only - there is no editable buffer under redirected/non-interactive input.
if (-not [Environment]::UserInteractive -or $Host.Name -ne 'ConsoleHost') {
    return
}

# Windows only. In pwsh $IsWindows is a real boolean; in Windows PowerShell it is undefined (and the OS
# is always Windows), so only bail when the variable exists *and* is false.
$CmdHlIsWindows = Get-Variable -Name 'IsWindows' -ValueOnly -ErrorAction 'Ignore'
if ($CmdHlIsWindows -eq $false) {
    return
}

# Per-session state in the global scope so the handler scriptblock (invoked later by PSReadLine) can
# reach it. CmdHlAlias (-> green) and CmdHlKnown (-> skip) are seeded from loaded commands; CmdHlKnownBg
# is the background-built set (auto-loadable cmdlets + PATH), handed over by reference when done;
# CmdHlReady flips true at that point; CmdHlBgPs/CmdHlBgHandle track the background build.
$global:CmdHlAlias = $null
$global:CmdHlKnown = $null
$global:CmdHlKnownBg = $null
$global:CmdHlReady = $false
$global:CmdHlBgPs = $null
$global:CmdHlBgHandle = $null
$global:CmdHlPathExt = @($env:PATHEXT -split ';' | Where-Object { $_ })
$global:CmdHlPathSep = [char[]]('\', '/', ':')

# The actual registration - defined as a global function so the deferred prompt wrapper (below) can call
# it, and so it can be invoked manually to (re)apply the bindings and rebuild the index on demand.
function global:Initialize-CommandHighlighting {
    # Probe the console buffer API once - here rather than at load, because the first GetBufferContents
    # call costs ~130ms of cold P/Invoke JIT that we don't want on the profile-load path. It throws in
    # hosts that don't implement it (VS Code integrated terminal, remoting, redirected output); bail
    # without binding in that case so the per-keystroke handler is never installed where it can't paint.
    try {
        $null = $Host.UI.RawUI.GetBufferContents(
            (New-Object 'System.Management.Automation.Host.Rectangle' 0, 0, 0, 0))
    } catch {
        return
    }

    # Seed the indexes from THIS session's already-loaded commands so the user's profile/session
    # functions, aliases, and loaded cmdlets resolve immediately. Enumerating with a pattern returns only
    # loaded commands (no module auto-load), so this is fast.
    $ic = $ExecutionContext.SessionState.InvokeCommand
    $global:CmdHlAlias = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $global:CmdHlKnown = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($c in $ic.GetCommands('*', [System.Management.Automation.CommandTypes]::Alias, $true)) {
        [void]$global:CmdHlAlias.Add($c.Name)
    }
    foreach ($c in $ic.GetCommands('*', [System.Management.Automation.CommandTypes]'Function,Cmdlet', $true)) {
        [void]$global:CmdHlKnown.Add($c.Name)
    }

    # Finish the index in the background: every auto-loadable cmdlet/function (module discovery) plus
    # every executable basename on PATH (a multi-dir scan). This is the slow part (~1s) but runs off the
    # typing thread; the handler merges the result in once it completes. Dispose any prior build first.
    if ($null -ne $global:CmdHlBgPs) {
        try { $global:CmdHlBgPs.Dispose() } catch { }
    }
    $global:CmdHlReady = $false
    $global:CmdHlBgPs = [PowerShell]::Create()
    [void]$global:CmdHlBgPs.AddScript({
        $set = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($c in (Get-Command -CommandType Function, Cmdlet -ErrorAction Ignore)) { [void]$set.Add($c.Name) }
        $exts = $env:PATHEXT -split ';' | Where-Object { $_ }
        foreach ($dir in ($env:PATH -split ';')) {
            if (-not $dir -or -not [System.IO.Directory]::Exists($dir)) { continue }
            foreach ($e in $exts) {
                try { foreach ($f in [System.IO.Directory]::EnumerateFiles($dir, "*$e")) { [void]$set.Add([System.IO.Path]::GetFileNameWithoutExtension($f)) } } catch { }
            }
        }
        , $set
    })
    $global:CmdHlBgHandle = $global:CmdHlBgPs.BeginInvoke()

    $CmdHlHandler = {
        param($key, $arg)

        # Wrap the whole keystroke - PSReadLine's own render (triggered by Insert below) plus our recolor -
        # in a DEC 2026 synchronized update so the terminal presents both as a single frame. Without it the
        # terminal can show PSReadLine's blue command token for one frame before our recolor lands; that is
        # the flicker, most visible on tokens that stay put while you type later args (e.g. after | or ;).
        # Terminals that don't support it ignore the sequence; a built-in timeout prevents any freeze.
        [Console]::Write("$([char]0x1b)[?2026h")
        try {
            # Always perform the edit first so typing is never blocked, whatever happens afterwards.
            if ($key.Key -eq [System.ConsoleKey]::Backspace) {
                [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteChar()
            } elseif ($key.Key -eq [System.ConsoleKey]::Delete) {
                [Microsoft.PowerShell.PSConsoleReadLine]::DeleteChar()
            } else {
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert($key.KeyChar)
            }

            # Merge the background index in once it's ready (cheap IsCompleted check; runs at most once).
            if (-not $global:CmdHlReady -and $null -ne $global:CmdHlBgHandle -and $global:CmdHlBgHandle.IsCompleted) {
                try {
                    $bg = $global:CmdHlBgPs.EndInvoke($global:CmdHlBgHandle)
                    if ($bg.Count -ge 1 -and $null -ne $bg[0]) {
                        # .psobject.BaseObject unwraps the pipeline's PSObject to the raw HashSet (whose
                        # Contains is ~10x faster than going through the adapter). O(1) hand-off by reference.
                        $global:CmdHlKnownBg = $bg[0].psobject.BaseObject
                    }
                    $global:CmdHlReady = $true
                } catch { }
                try { $global:CmdHlBgPs.Dispose() } catch { }
                $global:CmdHlBgPs = $null; $global:CmdHlBgHandle = $null
            }

            $ast = $null; $tokens = $null; $parseErrors = $null; $cursor = $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState(
                [ref]$ast, [ref]$tokens, [ref]$parseErrors, [ref]$cursor)
            if ($null -eq $ast) {
                return
            }

            # Every command position: the leading command plus anything after | ; && || and inside $(...).
            $commandAsts = $ast.FindAll(
                { $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true)
            if ($commandAsts.Count -eq 0) {
                return
            }

            # Resolve each command against the prebuilt indexes (O(1)); for anything not indexed, fall back
            # to a cheap live lookup with module auto-loading forced off (a "miss" with auto-load on costs
            # ~300ms - the whole reason for the indexes). The pref is global-scoped because the engine only
            # honours it there; it is restored in finally.
            $ic = $ExecutionContext.SessionState.InvokeCommand
            $loadedTypes = [System.Management.Automation.CommandTypes]'Alias,Function,Cmdlet'
            $overrides = [System.Collections.Generic.List[object]]::new()
            $prevAutoload = $global:PSModuleAutoLoadingPreference
            $global:PSModuleAutoLoadingPreference = 'None'
            try {
                foreach ($commandAst in $commandAsts) {
                    $nameAst = $commandAst.CommandElements[0]
                    # Only literal command names can be validated; skip `& $var`, `& (expr)`, etc.
                    if ($nameAst -isnot [System.Management.Automation.Language.StringConstantExpressionAst]) {
                        continue
                    }
                    $name = $nameAst.Value
                    # Skip empties, comments, and wildcard-bearing names (would pattern-match on lookup).
                    if ([string]::IsNullOrWhiteSpace($name) -or $name.StartsWith('#') -or $name -match '[\[\]\*\?]') {
                        continue
                    }

                    if ($global:CmdHlAlias.Contains($name)) {
                        $color = [ConsoleColor]::Green                          # alias
                    } elseif ($global:CmdHlKnown.Contains($name) -or ($null -ne $global:CmdHlKnownBg -and $global:CmdHlKnownBg.Contains($name))) {
                        continue                                               # function/cmdlet/app -> white-on-blue
                    } elseif ($name.IndexOfAny($global:CmdHlPathSep) -ge 0) {
                        # Path-like name (.\build.ps1, C:\tools\x.exe): check the file directly.
                        $pl = if ([System.IO.Path]::IsPathRooted($name)) { $name } else { [System.IO.Path]::Combine($PWD.ProviderPath, $name) }
                        $exists = [System.IO.File]::Exists($pl)
                        if (-not $exists) { foreach ($e in $global:CmdHlPathExt) { if ([System.IO.File]::Exists($pl + $e)) { $exists = $true; break } } }
                        if ($exists) { continue } elseif (-not $global:CmdHlReady) { continue } else { $color = [ConsoleColor]::Red }
                    } elseif (-not $global:CmdHlReady) {
                        continue                                               # index still building -> don't flag red yet
                    } else {
                        # Complete index says unknown; live-check loaded commands (auto-load off, so fast)
                        # to catch anything defined/imported this session, then fall to red. Cache the result.
                        $ci = $ic.GetCommand($name, $loadedTypes)
                        if ($null -ne $ci) {
                            if ($ci.CommandType -eq [System.Management.Automation.CommandTypes]::Alias) {
                                $color = [ConsoleColor]::Green; [void]$global:CmdHlAlias.Add($name)
                            } else {
                                [void]$global:CmdHlKnown.Add($name); continue
                            }
                        } else {
                            $color = [ConsoleColor]::Red                        # unknown command
                        }
                    }

                    $overrides.Add([pscustomobject]@{
                        Offset = $nameAst.Extent.StartOffset
                        Length = $nameAst.Extent.EndOffset - $nameAst.Extent.StartOffset
                        Color  = $color
                    })
                }
            } finally {
                $global:PSModuleAutoLoadingPreference = $prevAutoload
            }
            if ($overrides.Count -eq 0) {
                return
            }

            # Locate where the input (offset 0) sits on screen WITHOUT moving the cursor: the physical
            # cursor is at logical offset $cursor, so input-start = physicalCursor - $cursor (in cells,
            # wrapping at the buffer width). The old approach parked the cursor at 0 and back, which made
            # the caret jump and could scroll a long multi-command line - a source of the flicker.
            $width = $Host.UI.RawUI.BufferSize.Width
            $defaultBg = $Host.UI.RawUI.BackgroundColor
            $physCursor = $Host.UI.RawUI.CursorPosition
            $absInputStart = ($physCursor.Y * $width + $physCursor.X) - $cursor
            $inputX = $absInputStart % $width
            $inputY = [int][math]::Floor($absInputStart / $width)

            foreach ($override in $overrides) {
                $remaining = $override.Length
                $cell = $inputX + $override.Offset    # absolute cell index from the left edge of the input's first row
                while ($remaining -gt 0) {
                    $row = $inputY + [int][math]::Floor($cell / $width)
                    $col = $cell % $width
                    $countThisRow = [math]::Min($remaining, $width - $col)
                    $rect = New-Object 'System.Management.Automation.Host.Rectangle' `
                        $col, $row, ($col + $countThisRow - 1), $row
                    $strip = $Host.UI.RawUI.GetBufferContents($rect)
                    # Recolor only the cells that actually differ, and write back just the changed sub-range.
                    # PSReadLine leaves cells it considers unchanged alone, so they keep our color across
                    # keystrokes; rewriting them anyway is what made already-typed commands (e.g. after | or
                    # ;) flicker on every keystroke.
                    $minDiff = -1; $maxDiff = -1
                    for ($i = 0; $i -lt $countThisRow; $i++) {
                        $bufferCell = $strip.GetValue(0, $i)
                        if ($bufferCell.ForegroundColor -ne $override.Color -or $bufferCell.BackgroundColor -ne $defaultBg) {
                            $bufferCell.ForegroundColor = $override.Color
                            $bufferCell.BackgroundColor = $defaultBg
                            $strip.SetValue($bufferCell, 0, $i)
                            if ($minDiff -lt 0) { $minDiff = $i }
                            $maxDiff = $i
                        }
                    }
                    if ($minDiff -ge 0) {
                        $runLen = $maxDiff - $minDiff + 1
                        if ($runLen -eq $countThisRow) {
                            $sub = $strip
                        } else {
                            $sub = New-Object 'System.Management.Automation.Host.BufferCell[,]' 1, $runLen
                            for ($r = 0; $r -lt $runLen; $r++) { $sub.SetValue($strip.GetValue(0, $minDiff + $r), 0, $r) }
                        }
                        $coords = New-Object 'System.Management.Automation.Host.Coordinates' ($col + $minDiff), $row
                        $Host.UI.RawUI.SetBufferContents($coords, $sub)
                    }
                    $remaining -= $countThisRow
                    $cell += $countThisRow
                }
            }
        } catch {
            # A transient console race (resize, host quirk) must never disrupt editing - swallow and move on.
        } finally {
            # Always end the synchronized update, even on error, so the terminal is never left frozen.
            [Console]::Write("$([char]0x1b)[?2026l")
        }
    }

    # Bind the handler to every printable character (space + ASCII + Latin-1 supplement) plus Backspace and
    # Delete, so highlighting updates on every edit. Passing all chords to a single Set-PSReadLineKeyHandler
    # call binds each key individually but costs ~8x less than one call per key. Tab is deliberately excluded
    # so the profile's `Tab -> MenuComplete` binding is preserved; Ctrl+Backspace/Delete and the PSFzf
    # Ctrl+T/Ctrl+R chords are not in this set and are likewise untouched. The handler itself dispatches
    # Backspace/Delete to the matching PSReadLine edit functions before revalidating.
    $CmdHlKeys = [char[]] (0x20..0x7e + 0xA0..0xFF) | ForEach-Object { [string]$_ }
    $CmdHlKeys += 'Backspace', 'Delete'
    Set-PSReadLineKeyHandler -Chord $CmdHlKeys `
        -BriefDescription 'CmdExistenceHighlight' `
        -LongDescription 'Highlight unknown commands red and aliases green as you type' `
        -ScriptBlock $CmdHlHandler
}

# Defer the ~180ms binding off the profile-load critical path. Eventing (Register-EngineEvent OnIdle)
# would add its own ~125ms of first-use JIT at load, defeating the point, so instead wrap the prompt the
# same way profile.ps1 defers pshazz: capture the current prompt, then install a one-shot wrapper that
# binds the handler on the first prompt render and restores the original prompt. Defining functions is
# cheap, so profile load stays fast; the guard makes re-sourcing the profile safe (no double-wrapping).
if (-not $global:CmdHlDeferred) {
    $global:CmdHlDeferred = $true
    $global:CmdHlPriorPrompt = if (Test-Path 'function:\prompt') { $function:prompt } else { $null }
    function global:prompt {
        # Restore the original prompt first so this wrapper runs exactly once, then bind (before the
        # prompt is shown) and hand off. Binding is wrapped so a failure can never break the prompt.
        if ($null -ne $global:CmdHlPriorPrompt) {
            Set-Item -Path 'function:global:prompt' -Value $global:CmdHlPriorPrompt
        } else {
            Remove-Item -Path 'function:global:prompt' -ErrorAction 'Ignore'
        }
        try { Initialize-CommandHighlighting } catch { }
        if ($null -ne $global:CmdHlPriorPrompt) { & $global:CmdHlPriorPrompt } else { "PS $($PWD.Path)> " }
    }
}
