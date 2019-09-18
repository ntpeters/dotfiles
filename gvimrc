" Don't run Base16 shell script for GUIs
if exists('g:base16_shell_path')
    unlet g:base16_shell_path
endif

" Always use base16 theme in GUIs
call ntpeters#util#tryColorscheme('base16-material-darker')

" Set fonts
if !has('nvim')
    set guifont=FuraCode_NF:h10
    set guifont+=Fira_Code:h11
    if has('win32')
        set guifont+=Consolas:h11
    endif
elseif exists(':GuiFont')
    " TODO: Find way to add fallback fonts for nvim-qt
    " Unfortunately, nvim-qt uses its own `GuiFont` command instead of the
    " `guifont` option gvim uses. It will attempt to load the first font from
    " the `guifont` list, but if that fails it will simply fallback to the
    " default font instead of trying any other fonts in the `guifont` list.
    " It's also not possible to work around this by looping over a list of
    " fonts to try with `GuiFont`, since it only prints errors and doesn't
    " throw them to be caught. Comparing the output of `GuiFont` before/after
    " attempting to forcefully set the value is also not an option since it
    " will only reflect the new value after this file is done being sourced.
endif

" Enable DirectX rendering for Windows Vim
if has('win32') && !has('nvim')
    set renderoptions=type:directx
endif

" Put all gvimrc commands in their own group
augroup gvimrc
    autocmd!

    " Autosave on focus lost for gVim
    autocmd FocusLost * if filereadable(expand('%:p')) | :wall | endif
augroup END
