# Sets environment variables for the current PowerShell instance,
# and for the current user if running on Windows.

# Replicate the `IsWindows` environment variable from PowerShell Core in Windows PowerShell too.
# This is intentionally placed directly in the `Global` scope rather than the `Env` scope to match PowerShell Core.
# We're running on Windows if either:
#   - $IsWindows is true (PowerShell Core)
#   - $IsWindows does not exist (Windows PowerShell)
If ($Null -Eq (Get-Variable 'IsWindows' -Scope 'Global' -ErrorAction 'Ignore')) {
    New-Variable 'IsWindows' -Value $True -Scope 'Global' -Option 'ReadOnly'
}

# Ensure utilities are imported so that `Export-Variable` is defined.
$Util = "${Env:UserProfile}\.config\powershell\ntpetersUtil.psm1"
If (Test-Path($Util)) {
    Import-Module "$Util"
}

# Configure the prompt for cmd. See 'prompt /?' for info on accepted format codes.
Export-Variable 'Prompt' "${Env:UserName}`$Sat`$S${Env:ComputerName}`$Sin`$S`$P`$_`$`$`$S"

# Enable processing of ANSI sequences in ConEmu.
Export-Variable 'ConEmuANSI' 'ON'

# Use UTF-8 as the default encoding in Python for stdin/stdout/stderr.
Export-Variable 'PYTHONIOENCODING' 'utf-8'

# Tell ripgrep where to load its config from.
Export-Variable 'RIPGREP_CONFIG_PATH' "${Env:UserProfile}\.ripgreprc"

# Give CCache more space.
Export-Variable 'CCACHE_MAXSIZE' "15G"

# Use fd for fzf if available.
If ($Null -Ne $(Get-Command fd -ErrorAction 'Ignore')) {
    Export-Variable 'FZF_DEFAULT_COMMAND' "fd --type file"
}

# Counterpart to the existing $Profile variable pointing to a local profile not synced with dotfiles.
# This is intentionally placed directly in the `Global` scope rather than the `Env` scope to match $Profile.
$Global:LocalProfile = "${Env:UserProfile}\.config\powershell\local_profile.ps1"
