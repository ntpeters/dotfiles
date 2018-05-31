function Show-Colors {
    $Local:Colors = [Enum]::GetValues([ConsoleColor])
    $Local:MaxLength = ($Local:Colors | ForEach-Object { "$_ ".Length } | Measure-Object -Maximum).Maximum
    ForEach($Color in $Local:Colors) {
        Write-Host (" {0,2} {1,$Local:MaxLength} " -f [int]$Color,$Color) -NoNewline
        Write-Host "$Color" -Foreground $Color
    }
}

Set-Alias colors Show-Colors