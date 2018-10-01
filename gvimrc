
" Don't run Base16 shell script for GUIs
if exists('g:base16_shell_path')
    unlet g:base16_shell_path
endif

" Always use base16 theme in GUIs
call ntpeters#util#tryColorscheme('base16-material-darker')

if !has('nvim')
    set guifont=FuraCode_NF:h11
    set guifont+=Fira_Code:h11
    if has('win32')
        set guifont+=Consolas:h11
    endif
elseif exists(':GuiFont')
    " TODO: Find way to add fallback fonts for nvim-qt
    :GuiFont! FuraCode NF:h11
endif

if has('win32') && !has('nvim')
    set renderoptions=type:directx
endif

" Put all gvimrc commands in their own group
augroup gvimrc
    autocmd!

    " Autosave on focus lost for gVim
    autocmd FocusLost * if filereadable(expand('%:p')) | :wall | endif
augroup END

" Don't use menus for gvim
set guioptions=M
