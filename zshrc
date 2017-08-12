# Executes commands at the start of an interactive session.

# Ensure Antigen is installed
antigen_dir="$HOME/.antigen"
antigen_path="$antigen_dir/antigen.zsh"
if [[ ! -f "$antigen_path" ]]; then
    git clone https://github.com/zsh-users/antigen.git "$antigen_dir"
    #curl -L https://raw.githubusercontent.com/zsh-users/antigen/master/bin/antigen.zsh --create-dirs -o "$antigen_path"
fi

# Load Antigen
source "$antigen_path"

antigen use prezto

# Load Antigen bundles
antigen apply

# Ensure 256 color mode is enabled
export TERM=xterm-256color

# Link the Prezto dir from the Antigen dir to the home dir
if [[ ! -d "${ZDOTDIR:-$HOME}/.prezto" ]]; then
    echo "Linking Prezto into '~/.prezto'..."
    ln -s "$antigen_dir/bundles/sorin-ionescu/prezto" "${ZDOTDIR:-$HOME}/.prezto"
fi

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

export ANDROID_HOME=/Users/nate/Library/Android/sdk

export PATH=/usr/local/bin:"$PATH"

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

[[ -r $rvm_path/scripts/completion ]] && . $rvm_path/scripts/completion

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

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
