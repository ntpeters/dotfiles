# Set syntax highlighting colors for PowerShell

If ((Get-Module PSReadline).Version.Major -Ge 2) {
    # Color dictionary supports `ConsoleColor`, hex RGB, or VT control sequences
    Set-PSReadlineOption -Colors @{
        "Comment" = [ConsoleColor]::DarkCyan
        "Operator" = [ConsoleColor]::DarkMagenta
        "Variable" = [ConsoleColor]::Gray
        "Member" = [ConsoleColor]::Gray
        "Number" = [ConsoleColor]::Blue
        "Type" = [ConsoleColor]::Green
        "String" = [ConsoleColor]::Cyan
        "Parameter" = [ConsoleColor]::Red
        "Keyword" = [ConsoleColor]::Yellow
        "Command" = "$([char]0x1b)[97;44m"  # Foreground: White, Background: Blue
        "Default" = [ConsoleColor]::White
        }
} Else {
    # Use old style color options for PSReadline versions before 2.0
    Set-PSReadlineOption -TokenKind Comment -ForegroundColor DarkCyan
    Set-PSReadlineOption -TokenKind Operator -ForegroundColor DarkMagenta
    Set-PSReadlineOption -TokenKind Variable -ForegroundColor Gray
    Set-PSReadlineOption -TokenKind Member -ForegroundColor Gray
    Set-PSReadlineOption -TokenKind Number -ForegroundColor Blue
    Set-PSReadlineOption -TokenKind Type -ForegroundColor Green
    Set-PSReadlineOption -TokenKind String -ForegroundColor Cyan
    Set-PSReadlineOption -TokenKind Parameter -ForegroundColor Red
    Set-PSReadlineOption -TokenKind Keyword -ForegroundColor Yellow
    Set-PSReadlineOption -TokenKind Command -ForegroundColor White
    Set-PSReadlineOption -TokenKind Command -BackgroundColor DarkBlue
    Set-PSReadlineOption -TokenKind None -ForegroundColor White
}
