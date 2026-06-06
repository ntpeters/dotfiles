# PowerShell profile

# Set encoding
# Specifically not using Text.Encoding.UTF8 here, since that encoding includes a BOM which breaks terminal apps (especially when piping).
# This is the same encoding set by default for PowerShell Core, but it's set explicitly here for somewhat consistent behavior in Windows PowerShell (except for piping, which always seems to have a BOM added regardless of encoding).
$OutputEncoding = [Text.UTF8Encoding]::new()
$InputEncoding = [Text.UTF8Encoding]::new()
[Console]::OutputEncoding = $OutputEncoding
[Console]::InputEncoding = $InputEncoding
$PSDefaultParameterValues["Out-File:Encoding"] = "UTF8"
# Skip the chcp shell-out when the active code page is already UTF-8 (saves ~50ms per shell).
if ([Console]::OutputEncoding.CodePage -ne 65001) {
    chcp 65001 | Out-Null
}

# Report CWD to Windows Terminal via OSC 9;9 so `splitPane`/`duplicateTab` with
# splitMode: duplicate open new panes in the current directory. Wired via
# LocationChangedAction so it fires only when the CWD changes (not on every prompt),
# making it effectively free per-keystroke and independent of pshazz.
$ExecutionContext.SessionState.InvokeCommand.LocationChangedAction = {
    param($_, $eventArgs)
    [Console]::Write("$([char]27)]9;9;`"$($eventArgs.NewPath.ProviderPath)`"$([char]27)\")
}
[Console]::Write("$([char]27)]9;9;`"$($PWD.ProviderPath)`"$([char]27)\")

# Defer pshazz init to the first prompt invocation. This moves pshazz's ~330ms cost off
# the profile-load critical path; the first prompt blocks for that duration but the
# placeholder is replaced by pshazz's real prompt on first call. If pshazz isn't
# installed, the call inside the placeholder errors and the fallback prompt string is
# used — same effective behavior as not having pshazz, paid only on first prompt.
if (-not $pshazz) {
    function global:prompt {
        Remove-Item function:\global:prompt
        pshazz init
        if (Test-Path function:\global:prompt) {
            & $function:prompt
        } else {
            "PS $($PWD.Path)> "
        }
    }
}

# Set syntax colors
. "${Env:UserProfile}\.config\powershell\syntax-colors.ps1"

# Load environment variables
. "${Env:UserProfile}\.config\powershell\environment.ps1"

# Aliases
# `thefuck --alias` spawns Python on every shell start (~485ms). Defer that work until the
# user actually invokes `fuck` for the first time by installing a one-shot stub function
# that materializes the real alias on demand. Registered unconditionally — if thefuck is
# missing, the first call to `fuck` errors with the standard "command not found".
function global:fuck {
    Remove-Item function:fuck
    Invoke-Expression "$(thefuck --alias)"
    fuck @args
}
Set-Alias -Scope Global fu fuck

# Aliases registered unconditionally; if the underlying tool is missing, invocation
# produces a standard "command not found" — same UX as not having the alias at all.
Set-Alias pe path-extractor

# Unfortunately needed since `Set-Alias` doesn't support commands with args
function Invoke-Eza {
    eza --classify=auto --color=auto --icons=auto --git --no-permissions --header --group-directories-first @args
}

function Invoke-EzaLong {
    Invoke-Eza --long @args
}

Set-Alias ls Invoke-Eza -Scope 'Global' -Option 'AllScope'
Set-Alias ll Invoke-EzaLong -Scope 'Global' -Option 'AllScope'

# PSReadLine Settings
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadlineKeyHandler "Ctrl+Delete" KillWord
Set-PSReadlineKeyHandler "Ctrl+Backspace" BackwardKillWord
Set-PSReadlineKeyHandler "Ctrl+LeftArrow" BackwardWord
Set-PSReadlineKeyHandler "Ctrl+RightArrow" NextWord
Set-PSReadlineKeyHandler "Tab" MenuComplete
Set-PSReadLineOption -ExtraPromptLineCount 2

# Lazy-load PSFzf on first chord press (saves ~620ms per shell). PSFzf only matters for
# Ctrl+T (file picker) and Ctrl+R (history search); register placeholder PSReadLine
# handlers that import PSFzf, configure it via Set-PsFzfOption (which overwrites these
# placeholders with the real handlers), and then invoke the real handler so the user's
# keystroke takes effect on first press without requiring a second press.
$script:PSFzfBootstrapped = $false
function Initialize-PSFzfLazy {
    if ($script:PSFzfBootstrapped) { return $true }
    try {
        Import-Module PSFzf -ErrorAction Stop
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r' -EnableFd -FileSystemCommand 'fd . --color always --type directory {0}' -ErrorAction Stop
        $script:PSFzfBootstrapped = $true
        return $true
    } catch {
        Write-Warning "PSFzf lazy-load failed: $($_.Exception.Message)`nInstall with: Install-Module -Name PSFzf -Scope CurrentUser"
        return $false
    }
}
Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -ScriptBlock {
    if (Initialize-PSFzfLazy) {
        # Set-PsFzfOption has now overwritten this handler; invoke PSFzf's real handler directly.
        Invoke-FzfPsReadlineHandlerProvider
    }
}
Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -ScriptBlock {
    if (Initialize-PSFzfLazy) {
        Invoke-FzfPsReadlineHandlerHistory
    }
}

# Dynamic command-existence highlighting (zsh-style). Registered AFTER all other PSReadLine
# key-handler setup (Tab->MenuComplete line 85, PSFzf chords above) so the bulk printable-char
# binding cannot clobber them. Paints unresolved commands red, aliases green, and leaves valid
# commands' white-on-blue (from syntax-colors.ps1) intact.
. "${Env:UserProfile}\.config\powershell\command-highlighting.ps1"

# Import custom functions
$Util = "${Env:UserProfile}\.config\powershell\ntpetersUtil.psm1"
If (Test-Path($Util)) {
    Import-Module "$Util"
}

# Chocolatey profile is loaded only to register `choco` tab completion. Defer the full
# module import (~310ms) by registering a stub argument completer that imports the real
# module on first tab-completion invocation.
$ChocolateyProfile = "$Env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path $ChocolateyProfile) {
    $script:ChocolateyProfilePath = $ChocolateyProfile
    Register-ArgumentCompleter -CommandName choco,cup,cuninst,cinst -Native -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        Import-Module $script:ChocolateyProfilePath
        TabExpansion $commandAst.Extent.Text $wordToComplete
    }
}

# OpenSSHUtils is only used for occasional SSH file-permission repair, but its eager import
# costs ~1000ms (Add-Type for P/Invoke + multiple SID translations). Replace the import
# with stub functions that, on first invocation, remove themselves, import the real
# module, and forward to the freshly imported function with the same name.
$OpenSshUtils = "${Env:UserProfile}\.config\powershell\openssh\OpenSSHUtils.psm1"
if ($IsWindows -and (Test-Path $OpenSshUtils)) {
    $sshFns = 'Repair-FilePermission','Repair-SshdConfigPermission','Repair-SshdHostKeyPermission','Repair-AuthorizedKeyPermission','Repair-UserKeyPermission','Repair-UserSshConfigPermission','Enable-Privilege','Get-UserAccount','Get-UserSID'
    foreach ($fn in $sshFns) {
        $body = "foreach (`$f in @('$($sshFns -join "','")')) { Remove-Item function:`$f -ErrorAction Ignore }; Import-Module '$OpenSshUtils'; & '$fn' @args"
        Set-Item -Path "function:global:$fn" -Value ([scriptblock]::Create($body))
    }
}

# Lazy-load FuzzyFinderUtils the same way (~160ms saved). The module exports four
# interactive functions and matching aliases (fdp / rgp / fdo / rgo); the stubs replace
# themselves with the real exports on first call.
$ffuFns = 'Select-PathFromFd','Select-PathFromRg','Edit-PathFromFd','Edit-PathFromRg'
foreach ($fn in $ffuFns) {
    $body = "foreach (`$f in @('$($ffuFns -join "','")')) { Remove-Item function:`$f -ErrorAction Ignore }; Import-Module FuzzyFinderUtils; & '$fn' @args"
    Set-Item -Path "function:global:$fn" -Value ([scriptblock]::Create($body))
}
Set-Alias -Scope Global fdp Select-PathFromFd
Set-Alias -Scope Global rgp Select-PathFromRg
Set-Alias -Scope Global fdo Edit-PathFromFd
Set-Alias -Scope Global rgo Edit-PathFromRg

# Source local PowerShell profile if one exists.
If (Test-Path $Global:LocalProfile) {
    . $Global:LocalProfile
}

