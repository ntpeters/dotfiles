# Source: https://github.com/PowerShell/PowerShell/issues/20930#issuecomment-1899191414

# Polyfill for PowerShell 7.4+:
# Ensure that a legacy 'TabExpansion' function is still called, if defined.
if ($PSVersionTable.PSVersion -ge '7.4') {
    function TabExpansion2 {
        ### Copy of the parameter declarations from the built-in TabExpansion2 function.
        [CmdletBinding(DefaultParameterSetName = 'ScriptInputSet')]
        [OutputType([System.Management.Automation.CommandCompletion])]
        Param(
                [Parameter(ParameterSetName = 'ScriptInputSet', Mandatory = $true, Position = 0)]
                [AllowEmptyString()]
                [string] $inputScript,
                [Parameter(ParameterSetName = 'ScriptInputSet', Position = 1)]
                [int] $cursorColumn = $inputScript.Length,
                [Parameter(ParameterSetName = 'AstInputSet', Mandatory = $true, Position = 0)]
                [System.Management.Automation.Language.Ast] $ast,
                [Parameter(ParameterSetName = 'AstInputSet', Mandatory = $true, Position = 1)]
                [System.Management.Automation.Language.Token[]] $tokens,
                [Parameter(ParameterSetName = 'AstInputSet', Mandatory = $true, Position = 2)]
                [System.Management.Automation.Language.IScriptPosition] $positionOfCursor,
                [Parameter(ParameterSetName = 'ScriptInputSet', Position = 2)]
                [Parameter(ParameterSetName = 'AstInputSet', Position = 3)]
                [Hashtable] $options = $null
             )
             ###

        Set-StrictMode -Version 1

        if ($function:TabExpansion) { # Legacy function present: invoke it first.

        # Determine the arguments expected by the legacy TabExpansion function.
            $line = $inputScript.Substring(0, $cursorColumn) # the input line to the left of the cursor position
            [string] $lastWord = & { # the token immediately preceding the cursor position, if any.
            # NOTE:
            #  * The following *emulates* what PowerShell in earlier versions did, which was apparently
            #    custom parsing that included *partial* support for recognizing *quoted* tokens.
            #  * The following uses PowerShell's language parser instead, which results in
            #    *slightly different, but arguably IMPROVED* behavior (the old behavior is less helpful in all these cases):
            #     * If the cursor is right after a *syntactically complete* quoted
            #       string literal, $lastWord is set to '' (by definition, the argument is complete)
            #     * Similarly, *syntactically complete* $(...) / @(...) / (...) expressions result in $lastWord getting set to ''
            #     * Inside quoted string literals, *escaped* quotes are handled correctly.
                $tokens = $null
                # Note: The parser ignores incidental whitespace, so we place a dummy char. at the end.
                #       that helps us determine if a space *outside a string literal* is present.
                $null = [System.Management.Automation.Language.Parser]::ParseInput($line + [char] 1, [ref] $tokens, [ref] $null)
                if ($lastToken = $tokens[-2]) { # Get the penultimate token (the last one is always the EndOfInput token)
                if ($lastToken.Text -ne [char] 1) { # Only if the line doesn't end in a stand-alone space.
                    $(
                            if ($lastToken.Value) { $lastToken.Value } # string literal: output its *content*
                            else { $lastToken.Text } # otherwise (bareword, variable reference, ...): output its text.
                     ).TrimEnd([char] 1) # remove the dummy char.
                }
                }
            }

            # Invoke the legacy expansion function, which returns $null, one, or multiple strings.
            $result = TabExpansion $line $lastWord

            # If results were received:
            if ($result) {
                # Wrap them in a [System.Management.Automation.CommandCompletion] instance, as required
                # by TabExpansion2.

                # Construct the completion instance and output it.
                return [System.Management.Automation.CommandCompletion]::new(
                        [System.Collections.ObjectModel.Collection[System.Management.Automation.CompletionResult]] $result,
                        -1, # current match index (later used to keep track of cycling through multiple matches)
                        $cursorColumn - $lastWord.Length, # the start index of the token being completed.
                        $lastWord.Length # the length of the token being completed.
                        )
            }
            # No results? Continue below for default tab completion.

        }

        ###  The following is the original function body (with comments removed);
        ###  you can see the original function body in a pristine session by submitting $function:TabExpansion2)

        if ($psCmdlet.ParameterSetName -eq 'ScriptInputSet') {
            return [System.Management.Automation.CommandCompletion]::CompleteInput(
                    $inputScript,
                    $cursorColumn,
                    $options)
        }
        else { # 'AstInputSet'
            return [System.Management.Automation.CommandCompletion]::CompleteInput(
                    $ast,
                    $tokens,
                    $positionOfCursor,
                    $options)
        }

    }

}
