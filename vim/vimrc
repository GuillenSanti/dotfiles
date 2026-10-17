" General settings
set nocompatible                " Disable compatibility with old vi
set backspace=indent,eol,start  " Enable backspace in insert mode
set encoding=utf-8              " Use UTF-8 encoding
set fileformat=unix             " Use Unix line endings
set hidden                      " Allow switching buffers without saving

" Visual settings
set number                      " Show line numbers
set relativenumber              " Relative line numbers for easier navigation
set cursorline                  " Highlight the current line
set colorcolumn=80              " Show a vertical bar at column 80
highlight ColorColumn ctermbg=darkgray guibg=darkgray  " Customize the bar
set wrap                        " Enable line wrapping
set linebreak                   " Avoid breaking words at wrap
syntax on                       " Enable syntax highlighting
set background=dark             " Use a dark background for themes

" Indentation settings
set tabstop=4                   " Number of spaces for a tab
set shiftwidth=4                " Number of spaces for autoindent
set expandtab                   " Use spaces instead of tabs
set autoindent                  " Enable auto-indentation
set smartindent                 " Enable smart indentation

" Search settings
set ignorecase                  " Case-insensitive search
set smartcase                   " Case-sensitive if uppercase is used
set hlsearch                    " Highlight search results
set incsearch                   " Show matches as you type

" Performance
set lazyredraw                  " Faster scrolling for large files
set timeoutlen=500              " Shorten timeout for key sequences
set updatetime=300              " Faster updates for plugins

" Git and programming-specific settings
autocmd FileType gitcommit setlocal colorcolumn=72 textwidth=72 " Git messages
autocmd BufRead,BufNewFile *.py,*.js,*.ts,*.java setlocal tabstop=4 shiftwidth=4 expandtab " Programming files

" Keybindings
nnoremap <C-s> :w<CR>           " Ctrl+S to save
vnoremap <C-c> "+y              " Ctrl+C to copy to system clipboard
nnoremap <C-v> "+p              " Ctrl+V to paste from system clipboard

" Plugins (example placeholders)
" Uncomment if you use a plugin manager like vim-plug
" call plug#begin('~/.vim/plugged')
" Plug 'junegunn/fzf', {'do': { -> fzf#install() }}
" Plug 'airblade/vim-gitgutter'
" Plug 'tpope/vim-fugitive'
" Plug 'Yggdroot/indentLine'
" call plug#end()
