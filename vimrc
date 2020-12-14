set nocompatible
set hlsearch    " highlight all search results
set ignorecase  " do case insensitive search
set incsearch   " show incremental search results as you type
set number      " display line number
set noswapfile  " disable swap file

filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'
Plugin 'wincent/command-t'
Plugin 'tpope/vim-rbenv'
Plugin 'vim-ruby/vim-ruby'
Plugin 'tpope/vim-rails'
Plugin 'thoughtbot/vim-rspec'
Plugin 'tpope/vim-commentary'
Plugin 'ngmy/vim-rubocop'
Plugin 'tpope/vim-sensible'
Plugin 'christoomey/vim-tmux-navigator'
Plugin 'junegunn/fzf', { 'dir': '~/.fzf', 'do': 'yes \| ./install' }
Plugin 'christoomey/vim-tmux-runner'

call vundle#end()            " required
filetype plugin indent on    " required
syntax on

" automatically rebalance windows on vim resize"
autocmd VimResized * :wincmd =

" zoom a vim pane, <C-w>= to re-balance
nnoremap <leader>- :wincmd _<cr>:wincmd \|<cr>
nnoremap <leader>= :wincmd =<cr>

let mapleader = "\<Space>"
set relativenumber
autocmd InsertEnter * :set number
autocmd InsertLeave * :set relativenumber

runtime macros/matchit.vim

" check off a todo item and time stamp it
map gg ^rx: <Esc>:r! date +" [\%H:\%M]"<ENTER>kJA<Esc>$
" create a new todo item
map gt o_

