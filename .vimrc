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
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'bling/vim-bufferline'
Plugin 'airblade/vim-gitgutter'
" ,g (Configured below)

Plugin 'tpope/vim-fugitive'
Plugin 'camelcasemotion'
" ,w
" ,e
" ,b

Plugin 'SirVer/ultisnips'
Plugin 'honza/vim-snippets'
" Ctrl-j to insert
" Ctrl-l to list

Plugin 'scrooloose/nerdcommenter'
" <leader>c<space> toggle comment
" <leader>cl to comment

Plugin 'jacoborus/tender.vim'
Plugin 'powerman/vim-plugin-AnsiEsc'
Plugin 'w0rp/ale'
Plugin 'vim-scripts/bats.vim'

if !s:at_google
    Plugin 'noahfrederick/vim-skeleton'
    Plugin 'Valloric/YouCompleteMe'
    " <leader>jd Jump to definition
    Plugin 'fatih/vim-go'
endif

call vundle#end()

if s:at_google
    source /usr/share/vim/google/google.vim
    Glug youcompleteme-google
    Glug ultisnips-google
    Glug codefmt plugin[mappings]
    Glug codefmt-google
    Glug blaze plugin[mappings]='<leader>b'
    let g:blazevim_notify_after_blaze=1

    augroup autoformat_settings
        autocmd FileType bzl AutoFormatBuffer buildifier
        autocmd FileType go AutoFormatBuffer gofmt
        autocmd FileType textpb AutoFormatBuffer text-proto-format
        autocmd FileType gcl AutoFormatBuffer gclfmt
    augroup end
endif

" Valloric/YouCompleteMe
nnoremap <leader>jd :YcmCompleter GoTo<CR>

" bling/vim-airline
set laststatus=2
let g:airline_theme='tender'
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
nnoremap <leader>g :GitGutterSignsToggle<CR>
" turn off gitgutter in status line
let g:airline#extensions#hunks#enabled=0

" noahfrederick/vim-skeleton
let g:skeleton_template_dir='~/.vim/closet'
let g:skeleton_find_template={}
function! g:skeleton_find_template.java(path)
    return match(a:path, 'Test\.java$') != -1 ? 'test.java' : ''
endfunction
function! g:skeleton_find_template.go(path)
		return match(a:path, 'Test\.go$') != -1 ? 'test.go' : ''
endfunction

let g:skeleton_replacements={}
let g:skeleton_replacements_java={}
let g:skeleton_replacements_ruby={}

" This function tries to find the relative path from a parent directory to the
" given path.
" Ex: find_subpath('src/foo/bar', ['src']) = 'foo/bar'
"       - We find 'src'
"     find_subpath('src/foo/bar', ['src', 'foo']) = 'bar'
"       - We find 'foo' first
"     find_subpath('src/foo/bar', ['foo/bar', 'src']) = '.'
"       - We find 'foo/bar' first
"     find_subpath('src/foo/bar', ['parent']) = ''
"       - We don't find 'parent'
function! s:find_subpath(path, parents)
    let l:idx=-1

    for parent in a:parents
        let l:parent_idx=stridx(a:path,l:parent)
        if l:parent_idx != -1
            let l:idx=max([stridx(a:path,l:parent) + len(l:parent), l:idx])
        endif
    endfor

    if l:idx == -1
        return ''
    else
        let l:subpath=a:path[l:idx + 1:]
        if len(l:subpath) == 0
            return '.'
        else
            return l:subpath
        endif
    endif
endfunction

" Returns true is the given path is absolute
" Returns false if it is not
function! s:is_absolute(path)
    return stridx(a:path, getcwd()) == 0
endfunction

" expand('%:p') doesn't work for new files if their parent directories don't
" exist.
function! s:absolute(path)
    let l:path=fnamemodify(a:path, ':p')
    " strip trailing / that we may have just added
    let l:path=substitute(l:path, '/$', '', '')
    return s:is_absolute(l:path) ? l:path : getcwd() . '/' . l:path
endfunction

function! g:skeleton_replacements.INCLUDEGUARD()
    let l:guard=toupper(expand('%:t:r')) . '_H'

    let l:path=s:absolute(expand('%:h'))
    let l:subpath=s:find_subpath(l:path, ['src'])

    if len(l:subpath) != 0 && l:subpath != '.'
        let l:subpath=toupper(substitute(l:subpath, '/', '_', 'g'))
        let l:guard=l:subpath . '_' . l:guard
    endif

    return l:guard
endfunction

function! g:skeleton_replacements.DATE()
    return strftime('%B %-d, %Y')
endfunction

function! g:skeleton_replacements_java.PACKAGE()
    let l:path=s:absolute(expand('%:h'))
    let l:subpath=s:find_subpath(l:path, ['src', 'java'])

    if len(l:subpath) == 0 || l:subpath == '.'
        return ''
    else
        return 'package ' . substitute(l:subpath, '/', '.', 'g') . ';'
    endif
endfunction

function! g:skeleton_replacements_ruby.CLASSNAME()
    let l:name=expand('%:t:r')
    " \v: Every ASCII character not A-Z,a-z,0-9,_ have their special meanings
    " \u: Uppercase
    let l:name = substitute(l:name, '\v_(\w+)', '\u\1', 'g')
    " \<: start of word
    return substitute(l:name, '\<.', '\u&', '')
endfunction

" SirVer/ultisnips
let g:UltiSnipsExpandTrigger='<c-j>'
let g:UltiSnipsListSnippets='<c-l>'

" scrooloose/nerdcommenter
let NERDDefaultAlign='left'

" w0rp/ale
let g:airline#extensions#ale#enabled = 1

if s:at_google
  let g:ale_linters = {
\    'python': [],
\    'java': [],
\}
endif

"""""""""""""""
" GENERAL
"""""""""""""""

filetype plugin indent on
syntax on
let g:is_bash = 1

if has("termguicolors")
    set termguicolors
end
colorscheme tender

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
" If you forget to use sudoedit.
cmap w!! w !sudo tee %

nnoremap <leader>l :ls<CR>:b

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
nnoremap <leader>h :let @/='\V\<<C-r><C-a>\>'<CR>:set hls<CR>
" Highlight text that matches the visual selection
vnoremap <leader>h y:let @/='\V<C-r>"'<CR>:set hls<CR>
nnoremap <leader><space> :nohls<CR>

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

map <leader>s <leader>h:%s/<C-r>///<left>

"""""""""""""""
" FORMATTING
"""""""""""""""

set textwidth=80
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
" j = Remove comment leader when joining
" r = Add comment leader automatically
" o = Add comment leader automatically when entering insert mode
set formatoptions+=jro
" t = Auto-wrap text using textwidth
set formatoptions-=t
