set nocompatible

" If on Windows, link Vim directory to the standard location
if has('win32') && empty(glob('~/vimfiles'))
    :silent !cmd /c mklink /J "\%UserProfile\%/vimfiles" "\%UserProfile\%/.vim"
endif

" Install Plug if needed
call ntpeters#util#ensurePlug()

" Determine if NCM should load
let g:ncmSupported = has('nvim') || ntpeters#util#hasPythonModule('neovim')
let g:ncmVimCompatAvailable = g:ncmSupported && !has('nvim')

" Setup Plug
call plug#begin('~/.vim/bundle')

" Setup Plugins
" Vim 8 compatibility for NCM (requires Python neovim module)
Plug 'roxma/vim-hug-neovim-rpc', ntpeters#util#plugEnableIf(g:ncmVimCompatAvailable)
" Required by ncm2
Plug 'roxma/nvim-yarp', ntpeters#util#plugEnableIf(g:ncmSupported)
" Enable NCM for NeoVim always, and Vim if requirements are met
Plug 'ncm2/ncm2', ntpeters#util#plugEnableIf(g:ncmSupported)
Plug 'Shougo/neco-vim'
Plug 'roxma/ncm-clang'
Plug 'majutsushi/tagbar', { 'on': 'TagbarToggle' }
Plug 'luochen1990/rainbow'
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'scrooloose/nerdcommenter'
Plug 'myusuf3/numbers.vim'
Plug 'vim-scripts/a.vim'
Plug 'Raimondi/delimitMate'
Plug 'w0rp/ale'
Plug 'bling/vim-bufferline'
Plug 'airblade/vim-gitgutter'
Plug 'mbbill/undotree'
Plug 'tpope/vim-fugitive'
Plug 'godlygeek/tabular'
Plug 'jistr/vim-nerdtree-tabs'
Plug 'guns/xterm-color-table.vim'
Plug 'nathanaelkane/vim-indent-guides'
Plug 'ntpeters/vim-better-whitespace'
Plug 'gilsondev/searchtasks.vim'
Plug 'jeetsukumaran/vim-buffergator'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'tacahiroy/ctrlp-funky'
Plug 'tpope/vim-endwise'
Plug 'ervandew/supertab'
Plug 'terryma/vim-multiple-cursors'
Plug 'ludovicchabant/vim-gutentags', ntpeters#util#plugEnableIf(executable('ctags'))
Plug 'itchyny/lightline.vim'
Plug 'tpope/vim-obsession'
Plug 'dhruvasagar/vim-prosession'
Plug 'unblevable/quick-scope'

" Setup Theme Plugins
Plug 'nanotech/jellybeans.vim'
Plug 'alem0lars/vim-colorscheme-darcula'
call plug#end()

" Remap leader from '\' to ','
let mapleader = ","

" Disable unused builtin plugins
let g:loaded_gzip              = 1
let g:loaded_tar               = 1
let g:loaded_tarPlugin         = 1
let g:loaded_zip               = 1
let g:loaded_zipPlugin         = 1
let g:loaded_rrhelper          = 1
let g:loaded_2html_plugin      = 1
let g:loaded_vimball           = 1
let g:loaded_vimballPlugin     = 1
let g:loaded_getscript         = 1
let g:loaded_getscriptPlugin   = 1
let g:loaded_netrw             = 1
let g:loaded_netrwPlugin       = 1
let g:loaded_netrwSettings     = 1
let g:loaded_netrwFileHandlers = 1
let g:loaded_logipat           = 1

" Tell vim-whitespace to strip whitespace on save
let g:strip_whitespace_on_save = 1

" Enable CtrlP extensions
let g:ctrlp_extensions = ['funky']

" Configure Rainbow Parenthese
let g:rainbow_conf = {
    \   'guifgs': ['royalblue3', 'darkorange3', 'seagreen3', 'firebrick'],
    \   'ctermfgs': ['red', 'blue', 'yellow', 'cyan', 'magenta', 'lightred', 'lightblue', 'lightyellow', 'lightcyan', 'lightmagenta'],
    \   'operators': '_,_',
    \   'parentheses': ['start=/(/ end=/)/ fold', 'start=/\[/ end=/\]/ fold', 'start=/{/ end=/}/ fold'],
    \   'separately': {
    \       '*': {},
    \       'tex': {
    \           'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/'],
    \       },
    \       'lisp': {
    \           'guifgs': ['royalblue3', 'darkorange3', 'seagreen3', 'firebrick', 'darkorchid3'],
    \       },
    \       'vim': {
    \           'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/', 'start=/{/ end=/}/ fold', 'start=/(/ end=/)/ containedin=vimFuncBody', 'start=/\[/ end=/\]/ containedin=vimFuncBody', 'start=/{/ end=/}/ fold containedin=vimFuncBody'],
    \       },
    \       'html': {
    \           'parentheses': ['start=/\v\<((area|base|br|col|embed|hr|img|input|keygen|link|menuitem|meta|param|source|track|wbr)[ >])@!\z([-_:a-zA-Z0-9]+)(\s+[-_:a-zA-Z0-9]+(\=("[^"]*"|'."'".'[^'."'".']*'."'".'|[^ '."'".'"><=`]*))?)*\>/ end=#</\z1># fold'],
    \       },
    \       'css': 0,
    \   }
    \}

" Enable Rainbow Parenthesis
let g:rainbow_active = 1

let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']

" Put all vimrc auto commands in their own group
augroup vimrc
    autocmd!

    " Enable indent guides by default
    autocmd VimEnter * if exists(":IndentGuidesToggle") | execute ":IndentGuidesToggle" | endif

    " Open NERDTree if Vim was invoked with no args or a directory was opened
    autocmd VimEnter * if ((!argc() || (expand('%:p') == expand('%:p:h'))) && exists(":NERDTree")) | execute ":NERDTreeToggle" | endif

    " Close NERDTree if it's the last open buffer
    autocmd BufEnter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | :quit | endif

    " Autosave on focus lost for gVim
    autocmd FocusLost * :wall

    " Normalize split sizes when terminal is resized
    autocmd VimResized * :execute "normal \<C-w>="

    " Save/load current vim state when exiting/opening a file
    autocmd BufWinLeave ?* if ntpeters#util#shouldRestoreView() | mkview! | endif
    autocmd BufWinEnter ?* if ntpeters#util#shouldRestoreView() | silent! loadview | endif

    " Highlight anything beyond column 120 in red
    autocmd BufWinEnter,BufWinLeave * let w:m2=matchadd('ErrorMsg', '\%>120v.\+', -1)

    autocmd ColorScheme * highlight QuickScopePrimary ctermfg=119 ctermbg=22 cterm=underline guifg='#87ff5f' guibg='#005f00' gui=underline
    autocmd ColorScheme * highlight QuickScopeSecondary ctermfg=117 ctermbg=55 cterm=underline guifg='#87dfff' guibg='#5f00af' gui=underline
augroup END

set autoindent
set smartindent
" Tab width in spaces
set tabstop=4
" Size of indent in spaces
set shiftwidth=4
" Make spaces feel like real tabs
set softtabstop=4
" Convert tabs to spaces
set expandtab
" Intelligent backspace for space tabs. Makes a backspace delete one
" tabstop/shiftstop worth of spaces
set smarttab

" Set the encoding Vim uses for display
set encoding=utf-8
" Set the encoding Vim writes files with
set fileencoding=utf-8
set scrolloff=3
set noshowmode
set showcmd
set hidden
set wildmenu
set wildmode=list:longest
set wildignorecase
set cursorline
set cursorcolumn
set ruler
set backspace=indent,eol,start
set laststatus=2
set number
set autowrite
" Shorten messages to avoid 'hit enter' prompts
set shortmess=at

set ignorecase
set smartcase
set gdefault
set incsearch
set showmatch
set hlsearch

" Set auto text wrapping at column 80
set wrap
set textwidth=79
set formatoptions=qrn1

" Show whitespace characters
set list
set listchars=tab:▸\ ,eol:¬

" More sane split defaults
set splitbelow
set splitright

set modeline
set modelines=3

" Tell gitgutter to always show sign column
set signcolumn=yes

" Set shortcut for paste mode
set pastetoggle=<F10>

" Enable mouse support for Visual and Normal modes
set mouse=vn
if !has('nvim')
    set ttymouse=xterm2
endif
set ttyfast

" Must be set before GUI is loaded, don't move to gvimrc
" Disable menus, copy visual selection to clipboard, and preserve window sizing
set guioptions=Mak

" Enable persistent undo, and put undo files in their own directory to prevent
" pollution of project directories
if has('persistent_undo')
    call ntpeters#util#ensureDirectory('~/.vim/undo')
    " Remove current directory and home directory, then add .vim/undo as main
    " dir and current dir as backup dir
    set undodir-=.
    set undodir-=~/
    set undodir+=.
    set undodir^=~/.vim/undo//
    set undofile
endif

" Move swap files and backup files to their own directory to prevent pollution
call ntpeters#util#ensureDirectory('~/.vim/backup')
" Remove current directory and home directory, then add .vim/backup as main dir
" and current dir as backup dir
set backupdir-=.
set backupdir-=~/
set backupdir+=.
set backupdir^=~/.vim/backup//
" Enable standard backups if not built with 'writebackup'
if !has('writebackup')
    set backup
endif

call ntpeters#util#ensureDirectory('~/.vim/swap')
" Remove current directory and home directory, then add .vim/swap as main dir
" and current dir as backup dir
set directory-=.
set directory-=~/
set directory+=.
set directory^=~/.vim/swap//
set swapfile

" Set the directory for storing saved views
call ntpeters#util#ensureDirectory('~/.vim/views')
set viewdir=~/.vim/views
" Set options for 'mkview'
set viewoptions=         " Ensure no other options are set
set viewoptions+=cursor  " Cursor position in file
set viewoptions+=folds   " All local fold options (ie. opened/closed/manual folds)
set viewoptions+=slash   " Backslashes in filenames are replaced with foward slashes
set viewoptions+=unix    " Use Unix EOL

" Keys for CtrlP Funky
nnoremap <Leader>fu :CtrlPFunky<Cr>
" narrow the list down with a word under cursor
nnoremap <Leader>fU :execute 'CtrlPFunky ' . expand('<cword>')<Cr>

" Enable 'very magic' search mode
nnoremap / /\v
vnoremap / /\v

" Search for the word under the curoser with leader+/
nnoremap <Leader>/ *

" Unhighlight search terms with leader+space
nnoremap <leader><space> :noh<cr>

nnoremap <tab> %
vnoremap <tab> %
"
" Map Ctrl+N to open the NERDTree sidebar
nmap <silent> <c-n> :NERDTreeToggle<cr>

" Set Ctrl+S to save the file in all modes
nnoremap <silent> <c-s> :update<cr>
vnoremap <silent> <c-s> <c-c>:update<cr>
inoremap <silent> <c-s> <c-o>:update<cr>

" Disable arrow keys
nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <left> <nop>
nnoremap <right> <nop>
nnoremap j gj
nnoremap k gk

" Remap F1 to ESC in all modes for those times why you accidentally hit F1
inoremap <F1> <ESC>
nnoremap <F1> <ESC>
vnoremap <F1> <ESC>

" Remap semicolon to colon, because shift is for nerds
nnoremap ; :

" Set 'jj' to escape. Homerow OP
imap jj <ESC>

" Remaps for easier buffer navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Remaps for easier split opening
nnoremap <leader>w <C-w>v<C-w>l
nnoremap <leader><S-w> <C-w>s<C-w>j

" Shift+dir to jump paragraphs
nnoremap <S-k> <S-{>
nnoremap <S-j> <S-}>
" Shift+dir to jump to begin/end of line
nnoremap <S-h> ^
nnoremap <S-l> $

" More laziness remaps
nnoremap :q :q!
nnoremap :X :x

" Hit F9 to toggle spaces and tabs
nmap <silent> <F9> :call ntpeters#util#toggleTabs()<CR>

" Set colorscheme options based on detected 256 color support
if &t_Co == 256
    " Use 24-bit color if available
    if has('termguicolors')
        " Required to set Vim-specific sequences for RGB colors
        let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
        let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
        set termguicolors
    endif

    " Enable 256 colors in supported base16 themes
    let base16colorspace=256
endif

" Only allow Base16 themes to attempt running thier shell script in
" non-Windows, console Vim
if !has('win32')
    let g:base16_shell_path='~/.scripts/base16'
endif

" Base16 themes don't work well in Windows console
if !has('win32')
    call ntpeters#util#tryColorscheme('base16-material-darker')
else
    " Jellybeans works reasonably well everywhere, so it's a good fallback
    call ntpeters#util#tryColorscheme('jellybeans')
endif

set background=dark

" Set columns as 80 and 120
let &colorcolumn="80,120,121"
highlight ColorColumn ctermbg=19

" Set color for cursor line and column
highlight CursorLine ctermbg=232
highlight CursorColumn ctermbg=232

" Load local vim config if it exists
let s:localRcPath = glob('~/.vimrc.local')
if filereadable(s:localRcPath)
    execute 'source ' . s:localRcPath
endif
