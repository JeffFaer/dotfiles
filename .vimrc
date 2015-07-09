set nocompatible
let mapleader=','

let s:at_google=filereadable(expand('~/.at_google'))

"""""""""""""""
" PLUGINS
"""""""""""""""

filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'gmarik/Vundle.vim'
Plugin 'bling/vim-airline'
Plugin 'bling/vim-bufferline'
Plugin 'airblade/vim-gitgutter'
Plugin 'tpope/vim-fugitive'
Plugin 'camelcasemotion'
Plugin 'SirVer/ultisnips'
Plugin 'honza/vim-snippets'

if !s:at_google
    Plugin 'noahfrederick/vim-skeleton'
    Plugin 'Valloric/YouCompleteMe'
endif

call vundle#end()

if s:at_google
    source /usr/share/vim/google/google.vim
    Glug youcompleteme-google
    Glug ultisnips-google
endif

" Valloric/YouCompleteMe
nnoremap <leader>jd :YcmCompleter GoTo<CR>

" bling/vim-airline
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

" noahfrederick/vim-skeleton
let g:skeleton_template_dir='~/.vim/closet'
let g:skeleton_find_template={}
function! g:skeleton_find_template.java(path)
    return match(a:path, 'Test\.java$') != -1 ? 'test.java' : ''
endfunction

let g:skeleton_replacements={}
let g:skeleton_replacements_java={}

" This function tries to find the relative path from a directory whose name is
" in parents to the given path.
" Ex: find_subpath('src/foo/bar/file.ext', ['src']) = 'foo/bar'
"     find_subpath('src/foo/bar/file.ext', ['src', 'foo']) = 'bar'
function! s:find_subpath(path, parents)
    let l:path=a:path
    let l:head=fnamemodify(l:path, ':t')
    while l:path != '/' && index(a:parents, l:head) == -1
        let l:path=fnamemodify(l:path, ':h')
        let l:head=fnamemodify(l:path, ':t')
    endwhile

    if l:path == '/'
        return ''
    else
        return a:path[stridx(a:path,l:path) + len(l:path) + 1:]
    endif
endfunction

function! g:skeleton_replacements.INCLUDEGUARD()
    let l:guard=toupper(expand('%:t:r')) . '_H'

    let l:path=expand('%:p:h')
    let l:subpath=s:find_subpath(l:path, ['src'])

    if len(l:subpath) != 0
        let l:subpath=toupper(substitute(l:subpath, '/', '_', 'g'))
        let l:guard=l:subpath . '_' . l:guard
    endif

    return l:guard
endfunction


function! g:skeleton_replacements_java.PACKAGE()
    let l:path=expand('%:p:h')
    let l:subpath=s:find_subpath(l:path, ['src', 'java'])

    if len(l:subpath) == 0
        return ''
    else
        return 'package ' . substitute(l:subpath, '/', '.', 'g') . ';'
    endif
endfunction

" SirVer/ultisnips
let g:UltiSnipsExpandTrigger="<c-j>"
let g:UltiSnipsListSnippets="<c-l>"

"""""""""""""""
" GENERAL
"""""""""""""""

filetype plugin indent on
syntax on

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

augroup highlight
    au!

    " highlight long lines (81st character by default)
    au BufEnter,WinEnter *
          \ if &textwidth
          \|    let w:m1=matchadd('ErrorMsg', '\%' . (&textwidth + 1) . 'v.')
          \|endif
    au BufLeave *
          \ if exists('w:m1')
          \|    call matchdelete(w:m1)
          \|    unlet w:m1
          \|endif

    " trailing whitespace
    au BufEnter,WinEnter * let w:m2=matchadd('ErrorMsg', '\s\+$')
augroup END

"""""""""""""""
" SUBSTITUTE
"""""""""""""""

set gdefault

nmap <leader>s <leader>h:%s///<left>
vnoremap <leader>s :s///<left>

"""""""""""""""
" FORMATTING
"""""""""""""""

set textwidth=80
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
" j = Remove comment leader when joining
set formatoptions+=j

