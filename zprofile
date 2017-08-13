# Executes commands at login pre-zshrc.

# Source the common profile
source "$HOME/.profile"

# Antigen install directory
export ADOTDIR="${ADOTDIR:-$HOME/.antigen}"

# Path to Antigen's entry script, for sourcing
export ANTIGENZSH="${ANTIGENZSH:-$ADOTDIR/antigen.zsh}"

# Antigen config location
export ANTIGENRC="$HOME/.antigenrc"

# Temp Files
TMPPREFIX="${TMPDIR%/}/zsh"
if [[ ! -d "$TMPPREFIX" ]]; then
  mkdir -p "$TMPPREFIX"
fi
