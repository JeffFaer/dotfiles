"let $BASH_ENV = "$HOME/.bash_vim"

syntax on

"autocmd FileType c map <F6> :!gcc -o "%:p:r.out" "%:." <bar> more<CR>
"autocmd FileType c map <F7> :!%:p:r.out <CR>

set cindent
set tabstop=4
set shiftwidth=4
set expandtab

set hlsearch

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
set laststatus=2
