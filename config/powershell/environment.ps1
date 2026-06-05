# Sets environment variables for the current PowerShell instance,
# and for the current user if running on Windows.

# Append custom module directory to PSModulePath if it's not already there
$CustomModulePath = "${Env:UserProfile}\.config\powershell\modules"
if ($Env:PSModulePath -notcontains $CustomModulePath) {
    $Env:PSModulePath = "${Env:PSModulePath};$CustomModulePath"
}

# Replicate the $Is<platform> environment variables in Windows PowerShell, and add an
# $IsWSL variable in both PowerShell Core and Windows PowerShell.
# On PowerShell Core, $IsWindows / $IsLinux / $IsMacOS are built-in, so loading the
# OSCheckPortable module is only worth its ~150ms import cost on Windows PowerShell.
if ($PSEdition -eq 'Desktop') {
    Import-Module -Name OSCheckPortable
} elseif ($IsWindows) {
    # On Windows, /proc/version can't exist; skip the Select-String entirely (saves ~150ms).
    Set-Variable -Name IsWSL -Scope Global -Option ReadOnly -Force -Value $false
} else {
    Set-Variable -Name IsWSL -Scope Global -Option ReadOnly -Force -Value (
        [bool](Select-String -LiteralPath '/proc/version','/proc/sys/kernel/osrelease' -Pattern 'Microsoft|WSL' -Quiet -ErrorAction Ignore)
    )
}

# Ensure utilities are imported so that `Export-Variable` is defined.
$Util = "${Env:UserProfile}\.config\powershell\ntpetersUtil.psm1"
if (Test-Path -Path $Util) {
    Import-Module "$Util"
}

# Configure the prompt for cmd. See 'prompt /?' for info on accepted format codes.
Export-Variable 'Prompt' "${Env:UserName}`$Sat`$S${Env:ComputerName}`$Sin`$S`$P`$_`$`$`$S"

# TODO: cmd prompt, now featuring colors?!
# Doesn't work when run from Windows PowerShell since it fails to parse the escape codes
#Export-Variable 'Prompt' "`e[38;5;135m${Env:UserName}`e[0m]`$Sat`e[38;5;166m`$S${Env:ComputerName}`e[0m`$Sin`e[38;5;118m`$S`$P`$_`e[0m`$`$`$S"

# Opt out of PowerShell 7's telemetry. Saves ~25ms on every pwsh launch, since the
# telemetry init runs before the profile is read. PowerShell reads this from the user
# environment when the process starts, so persisting via Export-Variable means the value
# is in place for the *next* shell launch onward.
Export-Variable 'POWERSHELL_TELEMETRY_OPTOUT' '1'

# Enable processing of ANSI sequences in ConEmu.
Export-Variable 'ConEmuANSI' 'ON'

# Use UTF-8 as the default encoding in Python for stdin/stdout/stderr.
Export-Variable 'PYTHONIOENCODING' 'utf-8'

# Tell ripgrep where to load its config from.
Export-Variable 'RIPGREP_CONFIG_PATH' "${Env:UserProfile}\.ripgreprc"
Export-Variable 'BAT_CONFIG_PATH' "${Env:UserProfile}\.batrc"

# Give CCache more space.
Export-Variable 'CCACHE_MAXSIZE' "15G"

# Enable true colors if we're running in Windows Terminal
# if (-not [string]::IsNullOrWhiteSpace($Env:WT_SESSION)) {
    # Only set the term variables for the current session, not system-wide
    $Env:TERM = "xterm-256color"
    $Env:COLORTERM = "truecolor"
# }

Export-Variable 'PAGER' 'less'
Export-Variable 'LESS' '--quit-if-one-screen --RAW-CONTROL-CHARS --ignore-case --tilde --mouse'

Export-Variable 'EDITOR' 'nvim'
Export-Variable 'EDITOR_LINE_NUMBER_FORMAT' 'nvim +{1} {0}'
Export-Variable 'VISUAL' 'code'
Export-Variable 'VISUAL_LINE_NUMBER_FORMAT' 'code --goto {0}:{1}'

Export-Variable 'SCOOP' "${Env:UserProfile}\scoop"

# Use fd as the default fzf source. Set unconditionally — Export-Variable skips the
# expensive User-scope broadcast when the value is already set, and if fd is uninstalled
# fzf simply falls back to its built-in walker (no crash).
Export-Variable 'FZF_DEFAULT_COMMAND' "fd --type file"

# Counterpart to the existing $Profile variable pointing to a local profile not synced with dotfiles.
# This is intentionally placed directly in the `Global` scope rather than the `Env` scope to match $Profile.
$Global:LocalProfile = "${Env:UserProfile}\.config\powershell\local_profile.ps1"

# Source local environment if present
$LocalEnvironment = "${Env:UserProfile}\.config\powershell\local_environment.ps1"
if (Test-Path $LocalEnvironment) {
    . $LocalEnvironment
}
