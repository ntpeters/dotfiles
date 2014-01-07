# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="gallifrey"

# Aliases
alias zshconfig="vim ~/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"
alias sshmtu="ssh ntpeters@guardian.it.mtu.edu"
alias sshmtu2="ssh ntpeters@colossus.it.mtu.edu"
alias sshgpu="ssh ntpeters@ccsr.ee.mtu.edu"
alias sftpmtu="sftp ntpeters@guardian.it.mtu.edu"
alias sftpmtu2="sftp ntpeters@colossus.it.mtu.edu"
alias sftpgpu="sftp ntpeters@ccsr.ee.mtu.edu"
alias sshdev="ssh ntpeters@devbox.ntpeters.com"
alias sshresearch="ssh ntpeters@141.219.214.186"
alias sftpdev="sftp ntpeters@devbox.ntpeters.com"
alias intellij="sh /opt/idea-IC-129.713/bin/idea.sh"
alias intellij13="sh /opt/idea-IC-133.124/bin/idea.sh"
alias sublime="/opt/sublime_text_3/sublime_text"
alias cast="sudo systemctl stop iptables.service"
alias nvidia-profiler="/opt/cuda/bin/computeprof"
alias nprof=nvidia-profiler
alias lighttable="/opt/LightTable"
alias py="python"
alias updot="python ~/git/updot/updot.py"


alias vim="stty stop '' -ixoff ; vim"
ttyctl -f

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git yum )

source $ZSH/oh-my-zsh.sh

# Customize to your needs...
export PATH=/usr/lib64/qt-3.3/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin
export PATH=$PATH:/opt/cuda/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/cuda/lib:/opt/cuda/lib64
export JAVA_HOME=/usr/java/jdk1.7.0_40
export PATH=$PATH:/opt/AMDAPP/include
