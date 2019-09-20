# Sets environment variables that are not intended to be checked in to source control.
# These are typically machine-specific values that don't make sense to sync.
# This file will be sourced automatically by 'environment.ps1', so no additional module imports are needed.

# Override the default user or global install locations for Scoop.
#Export-Variable 'SCOOP' "${Env:UserProfile}\scoop"
#Export-Variable 'SCOOP_GLOBAL' "${Env:ProgramData}\scoop"