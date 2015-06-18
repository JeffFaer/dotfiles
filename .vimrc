set nocompatible
set backspace=indent,eol,start
set hidden                              "hide buffers
set rnu                                 "relative line numbers

let mapleader=','

set showmatch                           "matching brackets
set showcmd

set wildmenu
set wildmode=list:longest

nnoremap ; :

"""""""""""""""
" NAVIGATION
"""""""""""""""

nnoremap j gj
nnoremap k gk

nnoremap g: g;

noremap <left> <nop>
noremap <right> <nop>
noremap <up> <nop>
noremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>
inoremap <up> <nop>
inoremap <down> <nop>

nnoremap <leader>jd :YcmCompleter GoTo<CR>

"""""""""""""""
" HIGHLIGHT
"""""""""""""""

set hlsearch                            "search options
set ignorecase
set smartcase
set incsearch

nnoremap <leader>h :let @/='\<<C-r><C-w>\>'<CR>:set hls<CR>
nnoremap <leader><space> :nohl<CR>

"""""""""""""""
" SUBSTITUTE
"""""""""""""""

set gdefault

nmap <leader>s <leader>h:%s///<left>
vnoremap <leader>s :s///<left>

"""""""""""""""
" SYNTAX
"""""""""""""""

if has("syntax")
    syntax on
end

"mark .bash_aliases as a bash file
au BufNewFile,BufRead .bash_aliases call SetFileTypeSH("bash")

"""""""""""""""
" FORMATTING
"""""""""""""""

set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab

" 81st character
au BufEnter,WinEnter,BufRead * let w:m1=matchadd('ErrorMsg', '\%81v.')
" trailing whitespace
au BufEnter,WinEnter,BufRead * let w:m1=matchadd('ErrorMsg', '\s\+$')

"""""""""""""""
" STATUS LINE
"""""""""""""""

set laststatus=2
set statusline=
set statusline +=%1*\ %n\ %*            "buffer number
set statusline +=%5*%{&ff}%*            "file format
set statusline +=%3*%y%*                "file type
set statusline +=%4*\ %<%F%*            "full path
set statusline +=%2*%m%*                "modified flag
set statusline +=%1*%=%5l%*             "current line
set statusline +=%2*/%L%*               "total lines
set statusline +=%1*%4v\ %*             "virtual column number
set statusline +=%2*0x%04B\ %*          "character under cursor

hi User1 ctermfg=215
hi User2 ctermfg=167
hi User3 ctermfg=207
hi User4 ctermfg=155
hi User5 ctermfg=227

"""""""""""""""
" PLUGINS
"""""""""""""""

filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'gmarik/Vundle.vim'
Plugin 'Valloric/YouCompleteMe'

call vundle#end()

filetype plugin indent on

