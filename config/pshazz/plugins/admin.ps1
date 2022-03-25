# Plugin to display whether the current shell is running as admin in the prompt

function pshazz:admin:init {
    $admin = $global:pshazz.theme.admin

    $global:pshazz.admin = @{
        prompt_lbracket = $admin.prompt_lbracket;
        prompt_rbracket = $admin.prompt_rbracket;
        prompt_admin = $admin.prompt_admin;
    }
}

function global:pshazz:admin:prompt {
    $vars = $global:pshazz.prompt_vars

    $Local:User = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Local:IsAdmin = (New-Object Security.Principal.WindowsPrincipal $Local:User).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    if ($Local:IsAdmin) {
        $vars.admin_lbracket = $global:pshazz.admin.prompt_lbracket
        $vars.admin_rbracket = $global:pshazz.admin.prompt_rbracket
        $vars.admin = $global:pshazz.admin.prompt_admin
    }
}