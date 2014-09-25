# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

export ANTIGEN_DEFAULT_REPO_URL=https://github.com/robbyrussell/oh-my-zsh.git

source ~/.antigen/antigen.zsh

antigen bundle https://github.com/sorin-ionescu/prezto

antigen bundle pip
antigen bundle command-not-found

antigen bundle zsh-users/zsh-syntax-highlighting

antigen apply

# Ensure 256 color mode is enabled
export TERM=xterm-256color

# Link the Prezto dir from the Antigen dir to the home dir
if [[ ! -d "${ZDOTDIR:-$HOME}/.zprezto" ]]; then
    echo "Linking Prezto into '~/.zprezto'..."
    cp -lr ~/.antigen/repos/https-COLON--SLASH--SLASH-github.com-SLASH-sorin-ionescu-SLASH-prezto "${ZDOTDIR:-$HOME}/.zprezto"
fi

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
    source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

setopt correct

# Set theme
autoload -Uz promptinit
promptinit
prompt steeef

# Customize to your needs...

# Aliases¬
alias zshconfig="vim ~/.zshrc"
alias intellij="sh /opt/intellij/bin/idea.sh"
alias sublime="/opt/sublime_text_3/sublime_text"
alias cast="sudo systemctl stop iptables.service"
alias nvidia-profiler="/opt/cuda/bin/computeprof"
alias nprof=nvidia-profiler
alias lighttable="/opt/LightTable"
alias py="python"
alias updot="python ~/.updot/updot.py"
alias android-studio="/opt/android-studio/bin/studio.sh"
alias grep="grep -n "

alias vim="stty stop '' -ixoff ; vim"
ttyctl -f

# Set up paths
export PATH=/usr/lib64/qt-3.3/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin
export PATH=$PATH:/opt/cuda/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/cuda/lib:/opt/cuda/lib64
export JAVA_HOME=/usr/java/jdk1.7.0_40
export SCALA_HOME=/opt/scala-2.10.3
export PATH=$PATH:$SCALA_HOME/bin
export LLVM_SRC_ROOT=/opt/llvm-src
export PATH=$PATH:/home/nate/.gem/ruby/1.9.1/gems
