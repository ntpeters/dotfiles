# WTTabs — enumerate / inspect / pick / switch Windows Terminal tabs.
#
# Windows Terminal exposes no supported tab->process mapping, so this module pairs two
# sources: UI Automation for tab structure + switching, and an isolated ConPTY probe
# (AttachConsole + GetConsoleProcessList) for the live process/app-title per shell.
# They are joined by normalized title; renamed tabs decouple that title and stay
# unresolved (use Get-WTShell for ground truth). Windows + PowerShell 7 only.

Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes

$script:WTShellNames = 'pwsh.exe','powershell.exe','cmd.exe','bash.exe','wsl.exe','wslhost.exe','nu.exe','zsh.exe','fish.exe'
$script:WTWrappers   = 'agency.exe','conhost.exe','openconsole.exe','windowsterminal.exe'

# C# P/Invoke for the console probe. Compiled ONCE to a cached DLL (Get-WTProbeBinary) so
# the probe child can Add-Type -Path it (a fast assembly load) instead of paying a Roslyn
# compile on every spawn.
$script:WTProbeCS = @'
using System; using System.Runtime.InteropServices; using System.Text;
public static class WTConProbe {
  [DllImport("kernel32.dll", SetLastError=true)] public static extern bool FreeConsole();
  [DllImport("kernel32.dll", SetLastError=true)] public static extern bool AttachConsole(uint pid);
  [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)] public static extern int GetConsoleTitleW(StringBuilder sb, int n);
  [DllImport("kernel32.dll", SetLastError=true)] public static extern uint GetConsoleProcessList(uint[] buf, uint count);
}
'@

function Normalize-WTTitle {
    param([string]$Title)
    if (-not $Title) { return '' }
    ($Title -replace '^[⠀-⣿✳️\s]+','').Trim()   # strip leading spinner/status glyph (braille, ✳, VS16)
}

function Get-WTProbeBinary {
    # Returns a path the probe child can Add-Type:
    #   - a cached .dll  -> fast load, no compile (the normal path)
    #   - a .cs source   -> child compiles it (fallback if the DLL can't be produced)
    # The DLL is built once and persists in LOCALAPPDATA across sessions, so only the very
    # first probe ever pays Roslyn; every later call/session loads the prebuilt assembly.
    $base = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { $env:TEMP }
    $dir  = Join-Path $base 'WTTabs'
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $dll = Join-Path $dir 'WTConProbe.v1.dll'
    if (Test-Path $dll) { return $dll }
    try {
        Add-Type -TypeDefinition $script:WTProbeCS -OutputAssembly $dll -OutputType Library -ErrorAction Stop
        if (Test-Path $dll) { return $dll }
    } catch { }
    $cs = Join-Path $dir 'WTConProbe.cs'
    Set-Content -LiteralPath $cs -Value $script:WTProbeCS -Encoding UTF8
    $cs
}

function Get-WTConsoleInfo {
    # ISOLATED child pwsh: attaches to each WT shell's ConPTY, reads its live console title +
    # process list. Isolated because AttachConsole/FreeConsole would otherwise detach the
    # CALLING shell from its own terminal. Loads a prebuilt DLL to skip the Roslyn compile.
    $bin = Get-WTProbeBinary
    $src = @'
param([Parameter(Mandatory)][string]$Bin, [Parameter(Mandatory)][string]$Out)
$ErrorActionPreference = 'Stop'
Add-Type -Path $Bin
$all = Get-CimInstance Win32_Process
$nm = @{}; foreach ($p in $all) { $nm[[int]$p.ProcessId] = $p.Name }
$wtPids = ($all | Where-Object { $_.Name -eq 'WindowsTerminal.exe' }).ProcessId
$shells = $all | Where-Object { $_.ParentProcessId -in $wtPids -and $_.Name -match '^(pwsh|powershell|cmd|bash|wsl|nu|zsh|fish)\.exe$' }
$res = foreach ($s in $shells) {
    [WTConProbe]::FreeConsole() | Out-Null
    if ([WTConProbe]::AttachConsole([uint32]$s.ProcessId)) {
        $sb = New-Object System.Text.StringBuilder 1024
        [void][WTConProbe]::GetConsoleTitleW($sb, 1024)
        $buf = New-Object 'System.UInt32[]' 64
        $n = [WTConProbe]::GetConsoleProcessList($buf, 64)
        $pn = @(); for ($i = 0; $i -lt [int]$n; $i++) { $v = $nm[[int]$buf[$i]]; if ($v) { $pn += $v } }
        [WTConProbe]::FreeConsole() | Out-Null
        [pscustomobject]@{ Pid = [int]$s.ProcessId; Title = $sb.ToString(); Procs = $pn }
    }
}
[WTConProbe]::FreeConsole() | Out-Null
[System.IO.File]::WriteAllText($Out, (@($res) | ConvertTo-Json -Depth 5))
'@
    $tag = "wttabs_$PID"
    $hp  = Join-Path $env:TEMP "$tag.ps1"
    $op  = Join-Path $env:TEMP "$tag.json"
    Set-Content -LiteralPath $hp -Value $src -Encoding UTF8
    if (Test-Path $op) { Remove-Item $op -Force }
    Start-Process pwsh -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',$hp,$bin,$op -WindowStyle Hidden -Wait
    if (Test-Path $op) { @(Get-Content $op -Raw | ConvertFrom-Json) } else { @() }
}

function Get-WTShell {
    <#
    .SYNOPSIS
        Ground-truth list of every Windows Terminal shell/pane and what is running in it.
    .DESCRIPTION
        Attaches to each WT shell's ConPTY (in an isolated child process) and reads its live
        console title and process stack. Returns ShellPid, Process (the foreground app),
        AppTitle (spinner-stripped), RawTitle and Procs. Not bound 1:1 to UIA tabs, because
        Windows Terminal exposes no tab->PID key.
    .EXAMPLE
        Get-WTShell | Format-Table ShellPid, Process, AppTitle
    #>
    [CmdletBinding()]
    param()
    foreach ($e in (Get-WTConsoleInfo)) {
        $named = @($e.Procs | Where-Object { $_ })
        $app = $named | Where-Object { $_ -notin $script:WTShellNames -and $_ -notin $script:WTWrappers } | Select-Object -First 1
        if (-not $app) { $app = $named | Where-Object { $_ -in $script:WTShellNames } | Select-Object -First 1 }
        [pscustomobject]@{
            ShellPid = $e.Pid
            Process  = $app
            AppTitle = Normalize-WTTitle $e.Title
            RawTitle = $e.Title
            Procs    = $named
        }
    }
}

function Get-WTTab {
    <#
    .SYNOPSIS
        Enumerate Windows Terminal tabs (across all windows) via UI Automation.
    .DESCRIPTION
        Returns one object per tab: Hwnd, Index, Selected, Title, and the UIA Element used by
        Switch-WTTab. With -IncludeProcess, also resolves Process, ShellPid and AppTitle by
        matching each tab's normalized title against a live ConPTY probe (spawns an isolated
        helper, ~2-3s). Renamed tabs decouple their title from the app and stay unresolved;
        use Get-WTShell for complete ground truth.
    .EXAMPLE
        Get-WTTab | Format-Table Index, Selected, Title
    .EXAMPLE
        Get-WTTab -IncludeProcess | Format-Table Index, Process, ShellPid, Title
    #>
    [CmdletBinding()]
    param([switch]$IncludeProcess)

    $auto    = [System.Windows.Automation.AutomationElement]
    $tabCond = [System.Windows.Automation.PropertyCondition]::new(
                   $auto::ControlTypeProperty,
                   [System.Windows.Automation.ControlType]::TabItem)
    $wtPids  = (Get-Process WindowsTerminal -ErrorAction SilentlyContinue).Id
    $top     = $auto::RootElement.FindAll(
                   [System.Windows.Automation.TreeScope]::Children,
                   [System.Windows.Automation.Condition]::TrueCondition)
    $tabs = foreach ($w in $top) {
        if ($wtPids -notcontains $w.Current.ProcessId) { continue }
        $found = $w.FindAll([System.Windows.Automation.TreeScope]::Descendants, $tabCond)
        for ($i = 0; $i -lt $found.Count; $i++) {
            $t = $found.Item($i)
            $sel = $false
            try { $sel = $t.GetCurrentPattern(
                [System.Windows.Automation.SelectionItemPattern]::Pattern).Current.IsSelected } catch {}
            [pscustomobject]@{
                Hwnd = '0x{0:X}' -f $w.Current.NativeWindowHandle
                Index = $i; Selected = $sel
                Process = $null; AppTitle = $null; ShellPid = $null; Procs = $null
                Title = $t.Current.Name; Element = $t
            }
        }
    }
    $tabs = @($tabs)

    if ($IncludeProcess -and $tabs.Count) {
        $pool = Get-WTShell | ForEach-Object { $_ | Add-Member -NotePropertyName Used -NotePropertyValue $false -PassThru }
        $pool = @($pool)
        foreach ($t in $tabs) {
            $norm = Normalize-WTTitle $t.Title
            $m = $pool | Where-Object { -not $_.Used -and $_.AppTitle -eq $norm } | Select-Object -First 1
            if ($m) { $m.Used = $true; $t.Process = $m.Process; $t.ShellPid = $m.ShellPid; $t.Procs = $m.Procs; $t.AppTitle = $m.AppTitle }
        }
    }
    $tabs
}

function Switch-WTTab {
    <#
    .SYNOPSIS
        Switch to a Windows Terminal tab object returned by Get-WTTab.
    .EXAMPLE
        Get-WTTab | Where-Object Title -match 'IcM' | Switch-WTTab
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory, ValueFromPipeline)] $Tab)
    process {
        $Tab.Element.GetCurrentPattern(
            [System.Windows.Automation.SelectionItemPattern]::Pattern).Select()
    }
}

function Select-WTTab {
    <#
    .SYNOPSIS
        Pick a Windows Terminal tab with fzf (showing the running process) and switch to it.
    .DESCRIPTION
        Requires fzf on PATH. Lists every tab as 'process [index] title', shows the running
        process where resolvable (em dash otherwise), and switches on selection. Switching is
        always correct — it rides the tab's UIA element, independent of the process match.
    .EXAMPLE
        Select-WTTab
    .EXAMPLE
        Select-WTTab -Query 'claude'          # open the picker pre-filtered
    .EXAMPLE
        $t = Select-WTTab -PassThru           # switch and capture the chosen tab
    #>
    [CmdletBinding()]
    param([string]$Query, [switch]$PassThru)

    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-Error 'fzf not found on PATH. Install:  winget install junegunn.fzf'; return
    }
    $tabs = @(Get-WTTab -IncludeProcess)
    if ($tabs.Count -eq 0) { Write-Warning 'No Windows Terminal tabs found.'; return }

    $lines = for ($i = 0; $i -lt $tabs.Count; $i++) {
        $t = $tabs[$i]
        $mark = if ($t.Selected) { [char]0x25CF } else { ' ' }
        $proc = if ($t.Process) { $t.Process -replace '\.exe$','' } else { [char]0x2014 }  # em dash
        "{0}`t{1} {2,-11} [{3}] {4}" -f $i, $mark, $proc, $t.Index, $t.Title
    }
    $fzfArgs = @(
        '--delimiter=\t','--with-nth=2..','--nth=2..'
        '--layout=reverse','--height=40%','--border','--cycle'
        '--prompt=WT tab> ','--header=Switch WT tab   (proc  [idx]  title;  ● = active,  — = unbindable)'
    )
    if ($Query) { $fzfArgs += "--query=$Query" }

    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    $picked = $lines | & fzf @fzfArgs
    if (-not $picked) { return }
    $tab = $tabs[[int](($picked -split "`t",2)[0])]
    $tab | Switch-WTTab
    if ($PassThru) { $tab }
}

Export-ModuleMember -Function Get-WTTab, Get-WTShell, Switch-WTTab, Select-WTTab
