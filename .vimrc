if has("syntax")
    syntax on
end

if has("autocmd")
    filetype plugin indent on
end

set tabstop=4
set shiftwidth=4
set expandtab

set showmatch                           "matching brackets

set hlsearch                            "search options
set ignorecase
set smartcase
set incsearch

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

hi User1 ctermfg=215
hi User2 ctermfg=167
hi User3 ctermfg=207
hi User4 ctermfg=155
hi User5 ctermfg=227

set showcmd
set hidden                              "hide buffers
set rnu                                 "relative line numbers

"mark .bash_aliases as a bash file
au BufNewFile,BufRead .bash_aliases call SetFileTypeSH("bash")

"highlight the 81st character on a line
au BufEnter * highlight OverLength ctermbg=red ctermfg=white
au BufEnter * match OverLength /\%81v./

