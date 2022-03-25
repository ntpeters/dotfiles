# Plugin to define custom variables to use in the promp
# NOTE: The values will be expanded when they're loaded, so they must be properly escaped

function pshazz:var:init {
    $var = $global:pshazz.theme.var

    $global:pshazz.var = @{}
    $var_properties = Get-Member -InputObject $var -MemberType Properties
    foreach ($property in $var_properties) {
        $prefix = $null
        if ($property.Name -eq 'ps') {
            # Skip this section if we're not running in Windows PowerShell
            if ($PSEdition -ne 'Desktop') {
                continue;
            }
            $prefix = 'ps'
        } elseif ($property.Name -eq 'pwsh') {
            # Skip this section if we're not running in PowerShell Core
            if ($PSEdition -ne 'Core') {
                continue;
            }
            $prefix = 'pwsh'
        }

        if ($null -ne $prefix) {
            $prefixed_vars = $var | Select-Object -ExpandProperty $property.Name
            $prefixed_props = Get-Member -InputObject $prefixed_vars -MemberType Properties
            foreach ($prefixed_prop in $prefixed_props) {
                $value = $prefixed_vars | Select-Object -ExpandProperty $prefixed_prop.Name
                $global:pshazz.var.Add("${prefix}_$($prefixed_prop.Name)", "$value")
            }
        } else {
            $value = $var | Select-Object -ExpandProperty $property.Name
            $global:pshazz.var.Add("$($property.Name)", "$value")
        }
    }
}

function global:pshazz:var:prompt {
    $vars = $global:pshazz.prompt_vars

    foreach ($user_var in $global:pshazz.var.GetEnumerator()) {
        $vars.Add("var_$($user_var.Name)", "$($ExecutionContext.InvokeCommand.ExpandString($user_var.Value))")
    }
}