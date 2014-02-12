set nocompatible
filetype off

" Setup Vundle
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" Setup Plugin Bundles
Bundle 'gmarik/vundle'
Bundle 'Valloric/YouCompleteMe'
Bundle 'kien/rainbow_parentheses.vim'
Bundle 'scrooloose/nerdtree'
Bundle 'scrooloose/nerdcommenter'
Bundle 'myusuf3/numbers.vim'
Bundle 'vim-scripts/a.vim'
Bundle 'Raimondi/delimitMate'
Bundle 'scrooloose/syntastic'
Bundle 'bling/vim-airline'
Bundle 'bling/vim-bufferline'
Bundle 'airblade/vim-gitgutter'
Bundle 'mbbill/undotree'
Bundle 'tpope/vim-fugitive'
Bundle 'godlygeek/tabular'
Bundle 'jistr/vim-nerdtree-tabs'
Bundle 'guns/xterm-color-table.vim'
Bundle 'ntpeters/vim-indent-guides'
Bundle 'ntpeters/vim-better-whitespace'
"Bundle 'svenfuchs/vim-todo'
"Bundle 'svenfuchs/vim-layout'
Bundle 'edthedev/vim-todo'

" Setup Theme Bundles
Bundle 'nanotech/jellybeans.vim'
Bundle 'vim-scripts/xoria256.vim'

filetype plugin indent on
set modelines=0

syntax on

" Tell Airline to use Powerline fonts
let g:airline_powerline_fonts = 1

" Disable syntax checking for YouCompleteMe (using Syntastic instead)
" This is needed for vim-gitgutter to work properly with YCM
let g:ycm_enable_diagnostic_signs = 0

" Tell gitgutter to always show sign column
"let g:gitgutter_sign_column_always = 1

" Modify Rainbow Parenthesis colors
let g:rbpt_colorpairs = [
            \ ['brown',       'RoyalBlue3'],
            \ ['red',         'SeaGreen3'],
            \ ['darkgray',    'DarkOrchid3'],
            \ ['darkgreen',   'firebrick3'],
            \ ['darkcyan',    'RoyalBlue3'],
            \ ['darkred',     'SeaGreen3'],
            \ ['darkmagenta', 'DarkOrchid3'],
            \ ['brown',       'firebrick3'],
            \ ['gray',        'RoyalBlue3'],
            \ ['white',       'SeaGreen3'],
            \ ['darkmagenta', 'DarkOrchid3'],
            \ ['red',         'firebrick3'],
            \ ['darkgreen',   'RoyalBlue3'],
            \ ['darkcyan',    'SeaGreen3'],
            \ ['darkred',     'DarkOrchid3'],
            \ ['red',         'firebrick3'],
            \ ]

" Setup Rainbow Parenthesis
au VimEnter * RainbowParenthesesToggle
au Syntax * RainbowParenthesesLoadRound
au Syntax * RainbowParenthesesLoadSquare
au Syntax * RainbowParenthesesLoadBraces

" Enable indent guides by default
au VimEnter * IndentGuidesToggle

" Tell vim-whitespace to strip whitespace on save
au VimEnter * ToggleStripWhitespaceOnSave

" Tell vim-whitespace to disable the current line highlightin
au VimEnter * CurrentLineWhitespaceOff hard

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

set encoding=utf-8
set scrolloff=3
set showmode
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

" Set search key to /
nnoremap / /\v
vnoremap / /\v

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
"set list listchars=tab:>-,trail:.,extends:>

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
inoremap <up> <nop>
inoremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>
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
inoremap jj <ESC>

nnoremap <leader>w <C-w>v<C-w>l
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

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

set viewoptions=cursor,folds,slash,unix

" Save/load current vim state when exiting/opening a file
au VimLeave ?* mkview!
au VimEnter ?* silent loadview

" Enable 256 color mode
set t_Co=256

" Set the color scheme
colorscheme jellybeans

" Set columns as 80 and 120, and highlight anything beyond that in red
let &colorcolumn="80,".join(range(120,255),",")
highlight ColorColumn ctermbg=236
au BufWinEnter * let w:m2=matchadd('ErrorMsg', '\%>80v.\+', -1)

" Set color for cursor line and column
highlight CursorLine ctermbg=232
highlight CursorColumn ctermbg=232

" Current line number set colors to match vim-airline mode colors
" Set line number color for insert and replace modes
function! SetCursorLineNrColorInsert(mode)
    " Insert mode: white on green to match airline
    if a:mode == "i"
        highlight CursorLineNr ctermfg=white ctermbg=22
        " Replace mode: red on black
    elseif a:mode == "r"
        highlight CursorLineNr ctermfg=lightred ctermbg=black
    endif
endfunction

" Set line number color for insert mode
function! SetCursorLineNrColorVisual()
    set updatetime=0
    " Visual mode: white on red
    highlight CursorLineNr ctermfg=white ctermbg=52
    return ''
endfunction

" Resets the line number color to normal mode
function! ResetCursorLineNrColor()
    set updatetime=4000
    highlight CursorLineNr ctermfg=white ctermbg=27
endfunction

" Remaps for setting line number color when entering visual mode
vnoremap <silent> <expr> <SID>SetCursorLineNrColorVisual SetCursorLineNrColorVisual()
nnoremap <silent> <script> v v<SID>SetCursorLineNrColorVisual<left><right>
nnoremap <silent> <script> V V<SID>SetCursorLineNrColorVisual<left><right>
nnoremap <silent> <script> <C-v> <C-v><SID>SetCursorLineNrColorVisual<left><right>

" Auto commands for setting line number color based on mode
augroup CursorLineNrColorSwap
    autocmd!
    autocmd InsertEnter * call SetCursorLineNrColorInsert(v:insertmode)
    autocmd InsertLeave,VimEnter * call ResetCursorLineNrColor()
    autocmd CursorHold * call ResetCursorLineNrColor()
augroup END

" Load custom vim settings if they exist in the current directory
if filereadable(".vim.custom")
    so .vim.custom
endif
