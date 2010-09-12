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

if !exists("s:pathogen_disabled")
  let s:pathogen_disabled = []
endif

" For saving bundle_plugin data, pick a single canonical bundled_plugin file,
" unless already specified by user.

let s:platform_vimfiles = '$HOME/.vim'
if has('win32') || has('dos32') || has('win16') || has('dos16') || has('win95')
  let s:platform_vimfiles = '$HOME/vimfiles'
endif

if !exists('g:bundled_plugin')
  let g:bundled_plugin = fnameescape(expand(s:platform_vimfiles . '/bundled_plugins'))
endif

let s:done_bundles = ''

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
endfunction " }}}1

" parse all bundled_plugin files in &rtp
" NOTE: This (re)sets s:pathogen_disabled
function! pathogen#parse_bundled_plugins_files() " {{{1
  " set of 'bundled_plugins' files in root of runtime-path entries
  " can have more than one, but most typically expected to be a single entry
  " as ~/.vim/bundled_plugins
  let bpfs = filter(map(pathogen#split(&rtp), 'findfile("bundled_plugins", v:val)'), 'len(v:val) != 0')

  let s:pathogen_disabled = []
  for bpf in bpfs
    let bundled_plugins = readfile(bpf)

    let bundle = ''
    for line in bundled_plugins
      " skip blank lines
      if line =~ '^\s*$'
        continue
      endif
      " capture paths as new bundles
      if line =~ ':\s*$'
        let bundle = substitute(line, ':\s*$', '', '')
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
        call add(s:pathogen_disabled, plugin)
      endif
    endfor
  endfor

  let s:pathogen_disabled = pathogen#uniq(s:pathogen_disabled)
endfunction " }}}1

function! pathogen#list_bundle_plugins(bnd) " {{{1
  let plugins = []
  for plg in pathogen#list_plugins(0)
    if match(fnamemodify(plg, ':h'), a:bnd . '$') != -1
      call add(plugins, tolower(fnamemodify(plg, ':t')))
    endif
  endfor
  return pathogen#uniq(plugins)
endfunction " }}}1

" write plugin information to bundled_plugin file
function! pathogen#save_bundled_plugin_file() " {{{1
  let plugins = []
  for bnd in pathogen#list_bundle_dirs()
    call add(plugins, bnd . ':')
    for plg in pathogen#list_bundle_plugins(bnd)
      let status = ' '
      if pathogen#is_disabled_plugin(plg)
        let status = '-'
      endif
      call add(plugins, status . plg)
    endfor
  endfor
  echo "Saving " . g:bundled_plugin
  if writefile(plugins, g:bundled_plugin) == -1
    echoe "Couldn't save " . g:bundled_plugin . " file!"
  endif

au VimLeave * call pathogen#save_bundled_plugin_file()
endfunction " }}}1

function! pathogen#enable_plugin(plugin) " {{{1
  let plugin = tolower(a:plugin)
  let idx = index(s:pathogen_disabled, plugin)
  if idx != -1
    call remove(s:pathogen_disabled, idx)
    call pathogen#save_bundled_plugin_file()
  endif
endfunction " }}}1

function! pathogen#disable_plugin(plugin) " {{{1
  let plugin = tolower(a:plugin)
  if index(s:pathogen_disabled, plugin) == -1
    call add(s:pathogen_disabled, plugin)
    call pathogen#save_bundled_plugin_file()
  endif
endfunction " }}}1

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
endfunction " }}}1

" Takes an argument that can be 0 (all), 1 (enabled) or -1 (disabled) and returns a
" list of the plugins contained in every "bundle" dir, filtered according to
" the given argument.
" This asumes append_all_bundles() has been already called and
" s:pathogen_disabled is set.
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
endfunction " }}}1

" Returns a list of all "bundle" dirs.
function! pathogen#list_bundle_dirs() " {{{1
  return split(s:done_bundles,"\n")
endfunction " }}}1

" Check if plugin is disabled of not
function! pathogen#is_disabled_plugin(path) " {{{1
  let plugname = a:path =~# "after$"
        \ ? fnamemodify(a:path, ":h:t")
        \ : fnamemodify(a:path, ":t")
  return count(s:pathogen_disabled, plugname, 1)
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
