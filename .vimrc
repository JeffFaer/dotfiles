set nocompatible
let mapleader=','
augroup personal
autocmd!

"""""""""""""""
" PLUGINS
"""""""""""""""

filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'gmarik/Vundle.vim'
Plugin 'Valloric/YouCompleteMe'
Plugin 'bling/vim-airline'
Plugin 'bling/vim-bufferline'
Plugin 'airblade/vim-gitgutter'
Plugin 'tpope/vim-fugitive'
Plugin 'camelcasemotion'

call vundle#end()

" bling/vim-airline config
set laststatus=2
let g:airline_theme='simple'
let g:airline_powerline_fonts=1
let g:airline_section_z='%4l/%L %3v'
let g:airline_mode_map = {
    \ '__' : '-',
    \ 'n'  : 'N',
    \ 'i'  : 'I',
    \ 'R'  : 'R',
    \ 'c'  : 'C',
    \ 'v'  : 'V',
    \ 'V'  : 'V',
    \ '' : 'V',
    \ 's'  : 'S',
    \ 'S'  : 'S',
    \ '' : 'S',
    \ }

" bling/vim-bufferline
let g:bufferline_echo=0

" airblade/vim-gitgutter
let g:gitgutter_signs=0
nnoremap <leader>c :GitGutterSignsToggle<CR>
" turn off gitgutter in status line
let g:airline#extensions#hunks#enabled=0

"""""""""""""""
" GENERAL
"""""""""""""""

filetype plugin indent on

set backspace=indent,eol,start
set hidden                              "hide buffers
set rnu                                 "relative line numbers
set nu                                  "except for the '0' line

set showmatch                           "matching brackets
set showcmd

set wildmenu
set wildmode=list:longest

nnoremap ; :
vnoremap ; :

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

" Highlight whole words that match the one under the cursor
" \< \>      -> whole word
" <C-r><C-w> -> word under cursor
nnoremap <leader>h :let @/='\<<C-r><C-w>\>'<CR>:set hls<CR>
" Highlight text that matches the visual selection
" <C-r>"     -> paste the yank buffer
vnoremap <leader>h y:let @/='<C-r>"'<CR>:set hls<CR>
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

"""""""""""""""
" FORMATTING
"""""""""""""""

set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab

" highlight long lines (81st character by default)
au FileType java let b:col=100
au BufEnter,WinEnter * if !exists("b:col") | let b:col=80 | endif
au BufEnter,WinEnter * let w:m1=matchadd('ErrorMsg', '\%' . (b:col + 1) . 'v.')
au BufLeave * call matchdelete(w:m1)

" trailing whitespace
au BufEnter,WinEnter * let w:m2=matchadd('ErrorMsg', '\s\+$')

augroup END

