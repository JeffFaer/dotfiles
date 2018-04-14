if exists("did_load_filetypes")
    finish
endif

augroup filetypedetect
    au! BufNewFile,BufRead .bash_* setf sh
    au! BufNewFile,BufRead *.jsont setf javascript
augroup END
