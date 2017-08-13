# Common profile used by all shells

# Source environment vars
source "$HOME/.env"

typeset -gU cdpath fpath mailpath path


# Set the list of directories that Zsh searches for programs.
path=(
  /usr/local/{bin,sbin}
  $path
)

