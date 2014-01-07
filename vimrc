filetype  off
call pathogen#helptags()
call pathogen#incubate()
execute pathogen#infect()
filetype plugin indent on
set nocompatible
set modelines=0

syntax on

set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set smarttab

set encoding=utf-8
set scrolloff=3
set autoindent
set showmode
set showcmd
set hidden
set wildmenu
set wildmode=list:longest
set visualbell
set cursorline
set ttyfast
set ruler
set backspace=indent,eol,start
set laststatus=2
set number
set undofile

" Remap leader from '\' to ','
let mapleader = ","

nnoremap / /\v
vnoremap / /\v
set ignorecase
set smartcase
set gdefault
set incsearch
set showmatch
set hlsearch
nnoremap <leader><space> :noh<cr>
nnoremap <tab> %
vnoremap <tab> %

set wrap
set textwidth=79
set formatoptions=qrn1

set list
set listchars=tab:▸\ ,eol:¬
" Map Ctrl+N to open the NERDTree sidebar
nmap <silent> <c-n> :NERDTreeToggle<cr>
autocmd vimenter * if !argc() | NERDTree | endif
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif

noremap <silent> <c-s> :update<cr>
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

inoremap <F1> <ESC>
nnoremap <F1> <ESC>
vnoremap <F1> <ESC>

nnoremap ; :

" Autosave on focus lost for gVim
au FocusLost * :wa

inoremap jj <ESC>

nnoremap <leader>w <C-w>v<C-w>l
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

nnoremap :q :q!
nnoremap :X :x

set t_Co=256
colorscheme jellybeans
let &colorcolumn="80,".join(range(120,255),",")
highlight ColorColumn ctermbg=236
au BufWinEnter * let w:m2=matchadd('ErrorMsg', '\%>80v.\+', -1)
