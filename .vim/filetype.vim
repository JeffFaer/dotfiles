if exists("did_load_filetypes")
    finish
endif

augroup filetypedetect
    au! BufNewFile,BufRead .bash_* call SetFileTypeSH('bash')
    au! BufNewFile,BufRead *.jsont setf javascript
    au! BufNewFile,BufRead .tmux/* setf sh
    au! BufNewFile,BufRead .tmux.conf setf sh
    au! BufNewfile,BufRead *.log setf log
augroup END
