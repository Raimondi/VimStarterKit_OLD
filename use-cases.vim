function! UCFoldText()
  return repeat(' ', (v:foldlevel - 1)*2) . getline(v:foldstart+1)
endfunction
