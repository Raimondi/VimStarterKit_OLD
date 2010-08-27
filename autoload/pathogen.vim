" pathogen.vim - path option manipulation
" Maintainer:   Tim Pope <vimNOSPAM@tpope.org>
" Version:      1.2

" Install in ~/.vim/autoload (or ~\vimfiles\autoload).
"
" API is documented below.

if exists("g:loaded_pathogen") || &cp
  finish
endif
let g:loaded_pathogen = 1

if !exists("g:pathogen_disabled")
  let g:pathogen_disabled = []
endif

" Split a path into a list.
function! pathogen#split(path) abort " {{{1
  if type(a:path) == type([]) | return a:path | endif
  let split = split(a:path,'\\\@<!\%(\\\\\)*\zs,')
  return map(split,'substitute(v:val,''\\\([\\,]\)'',''\1'',"g")')
endfunction " }}}1

" Convert a list to a path.
function! pathogen#join(...) abort " {{{1
  if type(a:1) == type(1) && a:1
    let i = 1
    let space = ' '
  else
    let i = 0
    let space = ''
  endif
  let path = ""
  while i < a:0
    if type(a:000[i]) == type([])
      let list = a:000[i]
      let j = 0
      while j < len(list)
        let escaped = substitute(list[j],'[,'.space.']\|\\[\,'.space.']\@=','\\&','g')
        let path .= ',' . escaped
        let j += 1
      endwhile
    else
      let path .= "," . a:000[i]
    endif
    let i += 1
  endwhile
  return substitute(path,'^,','','')
endfunction " }}}1

" Convert a list to a path with escaped spaces for 'path', 'tag', etc.
function! pathogen#legacyjoin(...) abort " {{{1
  return call('pathogen#join',[1] + a:000)
endfunction " }}}1

" Remove duplicates from a list.
function! pathogen#uniq(list) abort " {{{1
  let i = 0
  let seen = {}
  while i < len(a:list)
    if has_key(seen,a:list[i])
      call remove(a:list,i)
    else
      let seen[a:list[i]] = 1
      let i += 1
    endif
  endwhile
  return a:list
endfunction " }}}1

" \ on Windows unless shellslash is set, / everywhere else.
function! pathogen#separator() abort " {{{1
  return !exists("+shellslash") || &shellslash ? '/' : '\'
endfunction " }}}1

" Convenience wrapper around glob() which returns a list.
function! pathogen#glob(pattern) abort " {{{1
  let files = split(glob(a:pattern),"\n")
  return map(files,'substitute(v:val,"[".pathogen#separator()."/]$","","")')
endfunction "}}}1

" Like pathogen#glob(), only limit the results to directories.
function! pathogen#glob_directories(pattern) abort " {{{1
  return filter(pathogen#glob(a:pattern),'isdirectory(v:val)')
endfunction "}}}1

" parse all bundled_plugin files in &rtp
" NOTE: This (re)sets g:pathogen_disabled
function! pathogen#parse_bundled_plugins_files()
  " set of 'bundled_plugins' files in root of runtime-path entries
  " can have more than one, but most typically expected to be a single entry
  " as ~/.vim/bundled_plugins
  let bpfs = filter(map(pathogen#split(&rtp), 'findfile("bundled_plugins", v:val)'), 'len(v:val) != 0')

  let g:pathogen_disabled = []
  let bundles = {'bundles' : {}, 'plugins' : {}}
  for bpf in bpfs
    let bundled_plugins = readfile(bpf)

    let path = ''
    for line in bundled_plugins
      " skip blank lines
      if line =~ '^\s*$'
        continue
      endif
      " capture paths as new bundles
      if line =~ ':\s*$'
        let path = line
        if has_key(bundles, path) == 0
          let bundles['bundles'][path] = {}
        endif
        continue
      endif
      " collect this plugin in the extant bundle
      let plugin = tolower(line)
      let status = 1
      if plugin =~ '^\s*-'
        let status = 0
      endif
      let plugin = substitute(plugin, '^\s*-\?\s*', '', '')
      if status == 0
        call add(g:pathogen_disabled, plugin)
      endif
      let bundles['bundles'][path][plugin] = status
      let bundles['plugins'][plugin] = status
    endfor
  endfor
  return bundles
endfunction


"""""""""""""
" Public API
"""""""""""""

" Prepend all subdirectories of path to the rtp, and append all after
" directories in those subdirectories.
function! pathogen#runtime_prepend_subdirectories(path) " {{{1
  let sep    = pathogen#separator()
  let before = pathogen#glob_directories(a:path.sep."*[^~]")
  let after  = pathogen#glob_directories(a:path.sep."*[^~]".sep."after")
  let rtp = pathogen#split(&rtp)
  let path = expand(a:path)
  call filter(rtp,'v:val[0:strlen(path)-1] !=# path')
  let &rtp = pathogen#join(pathogen#uniq(before + rtp + after))
  return &rtp
endfunction " }}}1

" For each directory in rtp, check for a subdirectory named dir.  If it
" exists, add all subdirectories of that subdirectory to the rtp, immediately
" after the original directory.  If no argument is given, 'bundle' is used.
" Repeated calls with the same arguments are ignored.  Multiple arguments can
" be used.
function! pathogen#runtime_append_all_bundles(...) " {{{1
  let sep = pathogen#separator()
  let names = a:0 ? a:000 : [ 'bundle' ]
  let list = []
  call pathogen#parse_bundled_plugins_files()
  for name in names
    if "\n".s:done_bundles =~# "\\M\n".name."\n"
      "return ""
      continue
    endif
    let s:done_bundles .= name . "\n"
    for dir in pathogen#split(&rtp)
      if dir =~# '\<after$'
        let list +=  pathogen#glob_directories(substitute(dir,'after$',name,'').sep.'*[^~]'.sep.'after') + [dir]
      else
        let list +=  [dir] + pathogen#glob_directories(dir.sep.name.sep.'*[^~]')
      endif
    endfor
  endfor
  call filter(list , ' !pathogen#is_disabled_plugin(v:val)') " remove disabled plugin directories from the list
  let &rtp = pathogen#join(pathogen#uniq(list))
  return 1
endfunction

let s:done_bundles = ''
" }}}1

" Takes an argument that can be 0 (all), 1 (enabled) or -1 (disabled) and returns a
" list of the plugins contained in every "bundle" dir, filtered according to
" the given argument.
" This asumes append_all_bundles() has been already called and
" g:pathogen_disabled is set, don't know if that's right.
function! pathogen#list_plugins(arg) " {{{1
  let sep = pathogen#separator()
  let list = []
  for name in split(s:done_bundles,"\n")
    for dir in pathogen#split(&rtp)
      if dir !~# '\<after$'
        let list +=  pathogen#glob_directories(dir.sep.name.sep.'*[^~]')
      endif
    endfor
  endfor
  if a:arg == 0 && type(a:arg) != 1
    return list
  elseif a:arg == 1
    return filter(list , ' !pathogen#is_disabled_plugin(v:val)') " remove disabled plugin directories from the list
  elseif a:arg == -1
    return filter(list , ' pathogen#is_disabled_plugin(v:val)') " remove enabled plugin directories from the list
  else
    echoe 'Something is wrong with this argument: '.a:arg
    return ''
  endif
endfunction "}}}1

" Returns a list of all "bundle" dirs.
function! pathogen#list_bundle_dirs() " {{{1
  return split(s:done_bundles,"\n")
endfunction " }}}1

" check if plugin is disabled of not
function! pathogen#is_disabled_plugin(path) " {{{1
  let plugname = a:path =~# "after$"
        \ ? fnamemodify(a:path, ":h:t")
        \ : fnamemodify(a:path, ":t")
  return count(g:pathogen_disabled, plugname,1)
endfunction " }}}1

" Invoke :helptags on all non-$VIM doc directories in runtimepath.
function! pathogen#helptags() " {{{1
  for dir in pathogen#split(&rtp)
    if dir[0 : strlen($VIM)-1] !=# $VIM && isdirectory(dir.'/doc') && (!filereadable(dir.'/doc/tags') || filewritable(dir.'/doc/tags'))
      helptags `=dir.'/doc'`
    endif
  endfor
endfunction " }}}1

" vim:set ft=vim ts=8 sw=2 sts=2:
