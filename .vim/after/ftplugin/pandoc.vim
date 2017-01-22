if filereadable(expand('%'))
    Pandoc! pdf
else
    let b:pandoc_command_autoexec_command="Pandoc! pdf"
    au BufWritePost <buffer>
          \ if exists('b:pandoc_command_autoexec_command')
          \|    unlet b:pandoc_command_autoexec_command
          \|    au! * <buffer>
          \|endif
endif
