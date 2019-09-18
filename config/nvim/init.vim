" Have NeoVim use Vim config and directories
set runtimepath^=~/.vim
set runtimepath+=~/.vim/after
set runtimepath^=~/.config/nvim
set runtimepath^=~/.config/neovim
if has('win32')
    set runtimepath^=~\AppData\Local\nvim
    set runtimepath^=~\AppData\Local\neovim
endif

let &packpath = &runtimepath
source ~/.vimrc
