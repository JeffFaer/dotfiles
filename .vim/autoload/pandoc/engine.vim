function! pandoc#engine#GetLatexEngine()
    let l:num_lines = line('$')
    if l:num_lines >= 1
        let l:line = getline(1)
        " If there's a metadata block, scan it.
        if l:line == '---'
            let l:line_num = 2
            let l:line = getline(l:line_num)

            " Scan until the metadata block closes or the end of the file.
            while l:line != '---' && l:line_num <= l:num_lines
                if l:line =~ '^latex-engine: \w\+'
                    return split(l:line)[1]
                end

                let l:line_num = l:line_num + 1
                let l:line = getline(l:line_num)
            endwhile
        endif
    end

    " Return the default latex engine if one isn't found.
    return g:pandoc#command#latex_engine
endfunction
