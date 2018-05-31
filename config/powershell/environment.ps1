$Util = "${Env:UserProfile}\.config\powershell\ntpetersUtil.psm1"
If (Test-Path($Util)) {
    Import-Module "$Util"
}

# Configure the prompt for cmd. See 'prompt /?' for info on accepted format codes.
Export-Variable 'Prompt' "${Env:UserName}`$Sat`$S${Env:ComputerName}`$Sin`$S`$P`$_`$`$`$S"

Export-Variable 'ConEmuANSI' 'ON'

Export-Variable 'PYTHONIOENCODING' 'utf-8'

Export-Variable 'RIPGREP_CONFIG_PATH' "${Env:UserProfile}\.ripgreprc"