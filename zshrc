# Executes commands at the start of an interactive session.

# Ensure Antigen is installed
if [[ ! -f "$ANTIGENZSH" ]]; then
    git clone https://github.com/zsh-users/antigen.git "$ADOTDIR"
fi

# Load Antigen
source "$ANTIGENZSH"
antigen init $ANTIGENRC

# Enable autocorrection of commands and args
setopt correct
setopt correct_all

# Set theme
autoload -Uz promptinit
promptinit
prompt steeef

# Aliases¬
alias zshconfig="vim $HOME/.zshrc"
alias py="python"

alias railserv="rails server -b $IP -p $PORT"
alias updot="python ~/.updot/updot.py"

# Prevent terminal from capturing Ctrl+S so Vim can assign it
alias vim="stty stop '' -ixoff ; vim"
ttyctl -f

# Set path to synced dotfiles for status check
export LOCAL_DOTFILES_REPOSITORY="$HOME/.dotfiles"

# Path to dotstat script
dotstat="$HOME/.updot/dotstat.sh"

# Ensure script is available, and get it if not
if [ ! -f $dotstat ]; then
    echo "Downloading dotstat.sh..."
    curl https://gist.githubusercontent.com/ntpeters/bb100b43340d9bf8ac48/raw/dotstat.sh -o $dotstat --create-dirs --progress-bar
    echo
fi
# Ensure script is executable
if [ ! -x $dotstat ]; then
    chmod a+x $dotstat
fi

# What's up with my dotfiles?
bash $dotstat

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
