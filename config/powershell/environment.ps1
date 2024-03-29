# Sets environment variables for the current PowerShell instance,
# and for the current user if running on Windows.

# Append custom module directory to PSModulePath if it's not already there
$CustomModulePath = "${Env:UserProfile}\.config\powershell\modules"
if ($Env:PSModulePath -notcontains $CustomModulePath) {
    $Env:PSModulePath = "${Env:PSModulePath};$CustomModulePath"
}

# Import module to replicate $Is<platform> environment variables in Windows PowerShell,
# and add an $IsWSL environment variable in both PowerShell Core and Windows PowerShell
Import-Module -Name OSCheckPortable

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

# Use fd for fzf if available.
if ($null -ne $(Get-Command fd -ErrorAction 'Ignore')) {
    Export-Variable 'FZF_DEFAULT_COMMAND' "fd --type file"
}

# Counterpart to the existing $Profile variable pointing to a local profile not synced with dotfiles.
# This is intentionally placed directly in the `Global` scope rather than the `Env` scope to match $Profile.
$Global:LocalProfile = "${Env:UserProfile}\.config\powershell\local_profile.ps1"

# Source local environment if present
$LocalEnvironment = "${Env:UserProfile}\.config\powershell\local_environment.ps1"
if (Test-Path $LocalEnvironment) {
    . $LocalEnvironment
}
