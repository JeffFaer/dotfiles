if exists("did_load_filetypes")
    finish
endif

augroup filetypedetect
    au! BufNewFile,BufRead *bash*
                \ let b:is_bash=1
                \|setf sh
    au! BufNewFile,BufRead *.jsont setf javascript
augroup END
