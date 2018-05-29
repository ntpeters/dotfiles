# Set syntax highlighting colors for PowerShell

Set-PSReadlineOption -TokenKind Comment -ForegroundColor DarkCyan
Set-PSReadlineOption -TokenKind Operator -ForegroundColor DarkMagenta
Set-PSReadlineOption -TokenKind Variable -ForegroundColor DarkGray
Set-PSReadlineOption -TokenKind Member -ForegroundColor DarkGray
Set-PSReadlineOption -TokenKind Number -ForegroundColor Blue
Set-PSReadlineOption -TokenKind Type -ForegroundColor Green
Set-PSReadlineOption -TokenKind String -ForegroundColor Cyan
Set-PSReadlineOption -TokenKind Parameter -ForegroundColor Red
Set-PSReadlineOption -TokenKind Keyword -ForegroundColor Yellow

Set-PSReadlineOption -TokenKind Command -ForegroundColor White
Set-PSReadlineOption -TokenKind Command -BackgroundColor DarkBlue

Set-PSReadlineOption -TokenKind None -ForegroundColor White