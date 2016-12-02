function! pandoc#engine#GetLatexEngine()
    let l:num_lines = line('$')
    if l:num_lines >= 1
        let l:first_line = getline(1)
        if l:first_line == '---'
            let l:line_num = 2
            while l:line_num <= l:num_lines
                let l:line = getline(l:line_num)
                if l:line == '---'
                    break
                end

                if l:line =~ '^latex-engine: \w\+'
                    return split(l:line)[1]
                end

                let l:line_num = l:line_num + 1
            endwhile
        endif
    end

    return g:pandoc#command#latex_engine
endfunction
