set nocompatible

" Install Plug if needed
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Setup Plug
call plug#begin('~/.vim/bundle')

" Setup Plugins
Plug 'Valloric/YouCompleteMe', { 'on': [] }
Plug 'luochen1990/rainbow', { 'on': 'RainbowToggle' }
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'scrooloose/nerdcommenter'
Plug 'myusuf3/numbers.vim'
Plug 'vim-scripts/a.vim'
Plug 'Raimondi/delimitMate'
Plug 'scrooloose/syntastic', { 'on': [] }
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'bling/vim-bufferline'
Plug 'airblade/vim-gitgutter'
Plug 'mbbill/undotree'
Plug 'tpope/vim-fugitive'
Plug 'godlygeek/tabular'
Plug 'jistr/vim-nerdtree-tabs'
Plug 'guns/xterm-color-table.vim'
"Plug 'ntpeters/vim-indent-guides'
Plug 'nathanaelkane/vim-indent-guides', { 'on': 'IndentGuidesToggle'}
Plug 'ntpeters/vim-better-whitespace'
"Plug 'svenfuchs/vim-todo'
"Plug 'svenfuchs/vim-layout'
Plug 'edthedev/vim-todo'
Plug 'jeetsukumaran/vim-buffergator'
"Plug 'kien/ctrlp.vim'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'tacahiroy/ctrlp-funky'
"Plug 'tpope/vim-rails'
"Plug 'vim-ruby/vim-ruby'
Plug 'tpope/vim-endwise'
Plug 'ervandew/supertab'
Plug 'ntpeters/vim-airline-colornum'
Plug 'terryma/vim-multiple-cursors'

" Setup Theme Plugins
"Plug 'nanotech/jellybeans.vim'
"Plug 'vim-scripts/xoria256.vim'
"Plug 'alem0lars/vim-colorscheme-darcula'
"Plug 'ciaranm/inkpot'
"Plug 'morhetz/gruvbox'
"Plug 'tomasr/molokai'
call plug#end()

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

"filetype plugin indent on
set modelines=0

" Don't use menus for gvim
set guioptions=M

"Delay syntatic load until we aren't doing anything
augroup LazySyntatic
  autocmd!
  autocmd CursorHold * :call plug#load('syntastic')
  autocmd CursorHold * :autocmd! LazySyntatic
augroup END

" Base16 themes require running a shell script...
let g:base16_shell_path='~/.go/bin/templates/shell/scripts'

" Tell Airline to use Powerline fonts
let g:airline_powerline_fonts = 1

" Disable syntax checking for YouCompleteMe (using Syntastic instead)
" This is needed for vim-gitgutter to work properly with YCM
let g:ycm_enable_diagnostic_signs = 0

" Tell gitgutter to always show sign column
set signcolumn=yes

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
au VimEnter * RainbowToggle

" Enable indent guides by default
au VimEnter * IndentGuidesToggle

" Tell vim-whitespace to strip whitespace on save
au VimEnter * EnableStripWhitespaceOnSave

" Tell vim-whitespace to disable the current line highlightin
au VimEnter * CurrentLineWhitespaceOff soft

" Enable CtrlP extensions
let g:ctrlp_extensions = ['funky']


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
set cursorline
set cursorcolumn
set ttyfast
set ruler
set backspace=indent,eol,start
set laststatus=2
set number
set autowrite

" Enable mouse support for Visual and Normal modes
set mouse=vn
set ttymouse=xterm2
set ttyfast

" Enable persistent undo, and put undo files in their own directory to prevent
" pollution of project directories
if exists("+undofile")
    " create the directory if it doesn't exists
    if isdirectory($HOME . '/.vim/undo') == 0
        :silent !mkdir -p ~/.vim/undo > /dev/null 2>&1
    endif
    " Remove current directory and home directory, then add .vim/undo as main
    " dir and current dir as backup dir
    set undodir-=.
    set undodir-=~/
    set undodir+=.
    set undodir^=~/.vim/undo//
    set undofile
endif

" Move swap files and backup files to their own directory to prevent pollution
" Create the directories if they do not exist
if isdirectory($HOME . '/.vim/backup') == 0
    :silent !mkdir -p ~/.vim/backup > /dev/null 2>&1
endif
" Remove current directory and home directory, then add .vim/undo as main dir
" and current dir as backup dir
set backupdir-=.
set backupdir-=~/
set backupdir+=.
set backupdir^=~/.vim/backup//
if isdirectory($HOME . '/.vim/swap') == 0
    :silent !mkdir -p ~/.vim/swap > /dev/null 2>&1
endif
" Remove current directory and home directory, then add .vim/undo as main dir
" and current dir as backup dir
set directory-=.
set directory-=~/
set directory+=.
set directory^=~/.vim/swap//

" Set the directory for storing saved views
if isdirectory($HOME . '/.vim/views') == 0
    :silent !mkdir -p ~/.vim/views > /dev/null 2>&1
endif
set viewdir=~/.vim/views

" Remap leader from '\' to ','
let mapleader = ","

" Keys for CtrlP Funky
nnoremap <Leader>fu :CtrlPFunky<Cr>
" narrow the list down with a word under cursor
nnoremap <Leader>fU :execute 'CtrlPFunky ' . expand('<cword>')<Cr>)

" Set search key to /
nnoremap / /\v
"vnoremap / /\v

set ignorecase
set smartcase
set gdefault
set incsearch
set showmatch
set hlsearch

" Unhighlight search terms with leader+space
nnoremap <leader><space> :noh<cr>

nnoremap <tab> %
vnoremap <tab> %

" Set auto text wrapping at column 80
set wrap
set textwidth=79
set formatoptions=qrn1

" Show whitespace characters
set list
set listchars=tab:▸\ ,eol:¬
"set listchars=tab:-_
"
" Map Ctrl+N to open the NERDTree sidebar
nmap <silent> <c-n> :NERDTreeToggle<cr>
autocmd vimenter * if !argc() | NERDTree | endif
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif

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

" Autosave on focus lost for gVim
au FocusLost * :wa

function! <SID>EscapePasteMode()
    if invpaste?
        set invpaste
    endif
endfunction

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

" More sane split defaults
set splitbelow
set splitright

" Normalize split sizes when terminal is resized
au VimResized * <C-w>=

" Shift+dir to jump paragraphs
nnoremap <S-j> <S-{>
nnoremap <S-k> <S-}>

" More laziness remaps
nnoremap :q :q!
nnoremap :X :x

" Set shortcut for paste mode
set pastetoggle=<F10>

" Used to toggle between spaces and tabs
function! <SID>ToggleTabs()
    set expandtab!
    retab!
endfunction
" Hit F9 to toggle spaces and tabs
nmap <silent> <F9> :call <SID>ToggleTabs()<CR>

" Set options for 'mkview'
set viewoptions=         " Ensure no other options are set
set viewoptions+=cursor  " Cursor position in file
set viewoptions+=folds   " All local fold options (ie. opened/closed/manual folds)
set viewoptions+=slash   " Backslashes in filenames are replaced with foward slashes
set viewoptions+=unix    " Use Unix EOL

" Save/load current vim state when exiting/opening a file
au VimLeave ?* mkview!
au VimEnter ?* silent loadview

" Enable 256 color mode
set t_Co=256

let base16colorspace=256
" Set the color scheme
"colorscheme jellybeans
colorscheme base16-material-darker
"colorscheme base16-material-palenight
"colorscheme base16-material
set background=dark

" Set columns as 80 and 120, and highlight anything beyond that in red
let &colorcolumn="80,120,121"
highlight ColorColumn ctermbg=19
au BufWinEnter,BufWinLeave * let w:m2=matchadd('ErrorMsg', '\%>80v.\+', -1)

" Set color for cursor line and column
highlight CursorLine ctermbg=232
highlight CursorColumn ctermbg=232

" Load custom vim settings if they exist in the current directory
if filereadable(".vim.custom")
    so .vim.custom
endif
