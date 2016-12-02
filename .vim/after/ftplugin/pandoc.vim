augroup pandoc_engine
    au BufWritePre <buffer> let b:pandoc_command_latex_engine=pandoc#engine#GetLatexEngine()
augroup END

if filereadable(expand('%'))
    let b:pandoc_command_latex_engine=pandoc#engine#GetLatexEngine()
    exec 'Pandoc! pdf --latex-engine=' b:pandoc_command_latex_engine
else
    let b:pandoc_command_autoexec_command="exec 'Pandoc! pdf --latex-engine=' b:pandoc_command_latex_engine"
    augroup pandoc_cleanup
        au BufWritePost <buffer>
                    \ if exists('b:pandoc_command_autoexec_command')
                    \|    unlet b:pandoc_command_autoexec_command
                    \|    au! pandoc_cleanup * <buffer>
                    \|endif
    augroup END
endif
