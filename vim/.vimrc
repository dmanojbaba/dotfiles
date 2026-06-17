set nocompatible
set encoding=utf-8

if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
Plug 'tpope/vim-fugitive'
Plug 'vim-airline/vim-airline'
call plug#end()

let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
filetype plugin indent on
syntax on

set mouse=a
set noerrorbells visualbell
autocmd GUIEnter * set t_vb=
set notimeout
set ttimeout

set lazyredraw
set number
set numberwidth=5
set relativenumber
set cursorline
set scrolloff=5
set sidescrolloff=10

set showmatch
set autoindent
set smartindent
set copyindent
set smarttab
set backspace=indent,eol,start
set nojoinspaces

set incsearch
set hlsearch
set ignorecase
set smartcase

set wrap
set linebreak
set list
set listchars=eol:↵,tab:→\ ,trail:⣿,nbsp:·

set wildmenu
set wildmode=longest:full,full
"set paste

set splitbelow
set splitright

set history=8192
set backupdir=~/.vim/.backup/,/tmp//
set directory=~/.vim/.swp/,/tmp//
set undodir=~/.vim/.undo/,/tmp//
set undofile
silent! call mkdir(expand('~/.vim/.backup'), 'p')
silent! call mkdir(expand('~/.vim/.swp'), 'p')
silent! call mkdir(expand('~/.vim/.undo'), 'p')

" YAML FileType Config
autocmd FileType yaml setlocal ai nu et ts=2 sts=2 sw=2

" END
