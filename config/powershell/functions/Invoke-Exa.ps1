function Invoke-Exa {
    & bash.exe -c "exa $args"
}

Set-Alias exa Invoke-Exa