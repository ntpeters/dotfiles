# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Setup path and environment variables
export PATH=/opt/android-studio/bin:"$PATH"
export PATH=/opt/idea/bin:"$PATH"

export SCALA_HOME=/opt/scala
export PATH=$SCALA_HOME/bin:"$PATH"

export JRE_HOME=/usr/java/latest/jre
export JDK_HOME=/usr/java/latest
export JAVA_HOME=/usr/java/latest
export PATH=$JRE_HOME/bin:"$PATH"
export PATH=$JAVA_HOME/bin:"$PATH"

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
