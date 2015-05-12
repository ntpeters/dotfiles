# Executes commands at the start of an interactive session.

# Ensure Antigen is installed
antigen_path="/home/$USER/.antigen/antigen.zsh"
if [[ ! -f "$antigen_path" ]]; then
    curl -L https://raw.githubusercontent.com/zsh-users/antigen/master/antigen.zsh --create-dirs -o "$antigen_path"
fi

# Set Antigen to pull packages from Oh-My-ZSH repo by default
export ANTIGEN_DEFAULT_REPO_URL=https://github.com/robbyrussell/oh-my-zsh.git

# Load Antigen
source "$antigen_path"

# Setup Antigen bundles
antigen bundle https://github.com/sorin-ionescu/prezto
antigen bundle pip
antigen bundle command-not-found
antigen bundle zsh-users/zsh-syntax-highlighting

# Load Antigen bundles
antigen apply

# Ensure 256 color mode is enabled
export TERM=xterm-256color

# Link the Prezto dir from the Antigen dir to the home dir
if [[ ! -d "${ZDOTDIR:-$HOME}/.zprezto" ]]; then
    echo "Linking Prezto into '~/.zprezto'..."
    cp -lr ~/.antigen/repos/https-COLON--SLASH--SLASH-github.com-SLASH-sorin-ionescu-SLASH-prezto "${ZDOTDIR:-$HOME}/.zprezto"
fi

# Source Prezto
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
    source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Enable autocorrection of commands and args
setopt correct
setopt correct_all

# Set theme
autoload -Uz promptinit
promptinit
prompt steeef

# Aliases¬
alias zshconfig="vim ~/.zshrc"
alias py="python"

alias railserv="rails server -b $IP -p $PORT"

# Prevent terminal from capturing Ctrl+S so Vim can assign it
alias vim="stty stop '' -ixoff ; vim"
ttyctl -f

# Set up paths
export PATH=/opt/android-studio/bin:"$PATH"
export PATH=/opt/idea/bin:"$PATH"

export SCALA_HOME=/opt/scala
export PATH=$SCALA_HOME/bin:"$PATH"

export JRE_HOME=/usr/java/latest/jre
export JDK_HOME=/usr/java/latest
export JAVA_HOME=/usr/java/latest
export PATH=$JRE_HOME/bin:"$PATH"
export PATH=$JAVA_HOME/bin:"$PATH"

export PATH=$HOME/.updot/updot:"$PATH"
