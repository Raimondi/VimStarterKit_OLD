" Status Line
" -----------
"
" Reset status line:
set statusline=

" Default color:
set statusline+=%*

" Relative file path:
set statusline+=%t

" Buffer number:
set statusline+=:%n

" Number of buffers:
set statusline+=%{len(filter(range(1,bufnr('$')),'buflisted(v:val)'))}

" Display file size: {{{
function! FileSize()
    let bytes = getfsize(expand("%:p"))
    if bytes <= 0
        return ""
    endif
    if bytes < 1024
        return bytes
    elseif bytes < 1048576
        return (bytes / 1024) . "K"
    elseif bytes < 1073741824
        return (bytes / 1048576) . "M"
	else
		return (bytes / 1073741824) . "G"
    endif
endfunction

" Display file size }}}
set statusline+=(%{FileSize()})

" Help flag:
set statusline+=[%H

" Use error color:
set statusline+=%#error#

" Modified flag:
set statusline+=%M

" Return to default color:
set statusline+=%*

" Readonly flag:
set statusline+=%R

" Preview window flag:
set statusline+=%W

" Type of  file flag:
set statusline+=%Y]

" set statusline+=%{'['.(&fenc!=''?&fenc:&enc).']['.&fileformat.']'}

" Add flag and highlight wrong values: {{{
" Add the variable with the name a:varName to the statusline. Highlight it as
" 'error' unless its value is in a:goodValues (a comma separated string)
function! AddStatuslineFlag(varName, goodValues, prefix, sufix)
  exec 'set statusline+='.a:prefix
  exec "set statusline+=%{RenderStlFlag(".a:varName.",'".a:goodValues."',1)}"
  set statusline+=%*
  exec "set statusline+=%{RenderStlFlag(".a:varName.",'".a:goodValues."',0)}"
  exec 'set statusline+='.a:sufix
endfunction

" Render stl flag:
"
" returns a:value or ''
"
" a:goodValues is a comma separated string of values that shouldn't be
" highlighted with the error group
"
" a:error indicates whether the string that is returned will be highlighted as
" 'error'
"
function! RenderStlFlag(value, goodValues, error)
  let goodValues = split(a:goodValues, ',')
  let good = index(goodValues, a:value) != -1
  if (a:error && !good) || (!a:error && good)
    return a:value
  else
    return ''
  endif
endfunction " }}}

" Alert me if endline are not unix:
call AddStatuslineFlag('&ff', 'unix', '', '')    "fileformat

" Alert me if file encoding is not UTF-8:
call AddStatuslineFlag('&fenc', 'utf-8', ',', '') "file encoding

" Indicate tabstop value: {{{
"execute 'set statusline+=,' . nr2char(187) . '–%{&tabstop}'
function! IndentStatus(prefix, sufix)
  if !&et
    return a:prefix . nr2char(187) . '–' . &shiftwidth . '/' . &tabstop . a:sufix
  else
    return a:prefix . nr2char(183) . nr2char(183) . &shiftwidth . '/' . &tabstop . a:sufix
  endif
endfunction
" }}}
set statusline+=[%{IndentStatus(',','')}]

" Warn on mixed indenting and wrong et value: {{{
" return '[&et]' if &et is set wrong
" return '[mixed-indenting]' if spaces and tabs are used to indent
" return an empty string if everything is fine
let b:statusline_tab_warning = ''
function! StatuslineTabWarning()
    if (getfsize(expand("<afile>")) >= 20*1024*1024 || getfsize(expand("<afile>")) == -2)
            let b:statusline_tab_warning = ''
    elseif !exists("b:statusline_tab_warning")
        let tabs = search('^\t', 'nw') != 0
        let spaces = search('^ ', 'nw') != 0

        if (tabs && spaces) && (&filetype != "help")
            let b:statusline_tab_warning =  '[mixed-indenting]'
        elseif (spaces && !&et) || (tabs && &et)
            let b:statusline_tab_warning = '[&et]'
        else
            let b:statusline_tab_warning = ''
        endif
    endif
    return b:statusline_tab_warning
endfunction

" Recalculate the tab warning flag when idle and after writing
"autocmd cursorhold,bufwritepost * unlet! b:statusline_tab_warning
autocmd bufwritepost * unlet! b:statusline_tab_warning

" display a warning if &et is wrong, or we have mixed-indenting  }}}
set statusline+=%#error#
set statusline+=%{StatuslineTabWarning()}
set statusline+=%*

" Warn on trailing spaces: {{{
" return '[\s]' if trailing white space is detected
" return '' otherwise
let b:statusline_trailing_space_warning = ''
function! StatuslineTrailingSpaceWarning()
    if (getfsize(expand("<afile>")) >= 20*1024*1024 || getfsize(expand("<afile>")) == -2)
            let b:statusline_trailing_space_warning = ''
    elseif !exists("b:statusline_trailing_space_warning")
        if search('\s\+$', 'nw') != 0
            let b:statusline_trailing_space_warning = '[\s]'
        else
            let b:statusline_trailing_space_warning = ''
        endif
    endif
    return b:statusline_trailing_space_warning
endfunction

" Recalculate the trailing whitespace warning when idle, and after saving
"autocmd cursorhold,bufwritepost * unlet! b:statusline_trailing_space_warning
autocmd bufwritepost * unlet! b:statusline_trailing_space_warning

" puts the trailing spaces flag on the statusline }}}
set statusline+=%#error#
set statusline+=%{StatuslineTrailingSpaceWarning()}
set statusline+=%*

" Warn on "long lines": {{{
"return a warning for "long lines" where "long" is either &textwidth or 80 (if
"no &textwidth is set)
"
"return '' if no long lines
"return '[#x,my,$z] if long lines are found, were x is the number of long
"lines, y is the median length of the long lines and z is the length of the
"longest line
function! StatuslineLongLineWarning()
    if (getfsize(expand("<afile>")) >= 20*1024*1024 || getfsize(expand("<afile>")) == -2)
            let b:statusline_long_line_warning = ""
    elseif !exists("b:statusline_long_line_warning")
        let long_line_lens = s:LongLines()

        if len(long_line_lens) > 0
            let b:statusline_long_line_warning = "[" .
                        \ '#' . len(long_line_lens) . "," .
                        \ 'm' . s:Median(long_line_lens) . "," .
                        \ '$' . max(long_line_lens) . "]"
        else
            let b:statusline_long_line_warning = ""
        endif
    endif
    return b:statusline_long_line_warning
endfunction

"return a list containing the lengths of the long lines in this buffer
function! s:LongLines()
    let threshold = (&tw ? &tw : 80)
    let spaces = repeat(" ", &ts)

    let long_line_lens = []

    let i = 1
    while i <= line("$")
        let len = strlen(substitute(getline(i), '\t', spaces, 'g'))
        if len > threshold
            call add(long_line_lens, len)
        endif
        let i += 1
    endwhile

    return long_line_lens
endfunction

"find the median of the given array of numbers
function! s:Median(nums)
    let nums = sort(a:nums)
    let l = len(nums)

    if l % 2 == 1
        let i = (l-1) / 2
        return nums[i]
    else
        return (nums[l/2] + nums[(l/2)-1]) / 2
    endif
endfunction

" Recalculate the long line warning when idle and after saving
"autocmd cursorhold,bufwritepost * unlet! b:statusline_long_line_warning
autocmd bufwritepost * unlet! b:statusline_long_line_warning

" Alert me of long lines:  }}}
set statusline+=%{StatuslineLongLineWarning()}

" Start right aligned items:
set statusline+=\ %=

" Display date and time:
"set statusline+=\(%{strftime(\"%D\ %T\",getftime(expand(\"%:p\")))}\)

" Show moon phase:  {{{
" Phase of the Moon calculation
let time = localtime()
let fullday = 86400
let offset = 592500
let period = 2551443
let phase = (time - offset) % period
let phase = phase / fullday

" Moon phase and paste flag for the statusline. Weird, eh?
function! Moon()
  return printf(&paste ? "[%d]" : "(%d)", g:phase)
endfunction

" Display moon face:  }}}
"set statusline+=\ Moon:%{Moon()}

" Line number
set statusline+=\ %l,

" Column number:
set statusline+=%c

" Virtual column number:
set statusline+=%V

" Percentage through file/Number of lines in buffer:
set statusline+=\ %P/%L

" vim: set foldmethod=marker foldcolumn=2 foldtext=MyFoldText():
