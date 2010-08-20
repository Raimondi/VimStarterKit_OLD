
if has('gui_macvim')
  set fuoptions=maxvert,maxhorz " Full-screen mode uses the full screen
  ":h macvim-shift-movement
  let macvim_hig_shift_movement = 1
endif

" Show toolbar.
set guioptions+=T
