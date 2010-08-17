" If this is on, it might interfere with pathogen:
filetype off

" Let pathogen perform its magic:
exec 'set runtimepath+=' . expand('~/.vim/bundle/vim-pathogen')

" Disabled plugins:
let pathogen_disabled = []
" -CSApprox
let pathogen_disabled += ['csapprox']
" -NERDCommenter
let pathogen_disabled += ['nerdcommenter']
" -SnipMate
let pathogen_disabled += ['snipmate']
" -VimOutliner
let pathogen_disabled += ['vimoutliner']
" -delimitMate
let pathogen_disabled += ['delimitMate']

call pathogen#runtime_append_all_bundles()

set nocompatible " NEVER change this! Use Vim mode, not vi mode.
filetype plugin indent on " Enable automatic settings based on file type
syntax on " Enable color syntax highlighting

""""""""""
" Options
""""""""""
" Use :help 'option (including the ' character) to learn more about each one.
"
" Buffer (File) Options:
set hidden " Edit multiple unsaved files at the same time
set confirm " Prompt to save unsaved changes when exiting
" Keep various histories between edits
set viminfo='1000,f1,<500,:100,/100

" Search Options:
set hlsearch " Highlight searches. See below for more.
set ignorecase " Do case insensitive matching...
set smartcase " ...except when using capital letters
set incsearch " Incremental search

" Insert (Edit) Options:
"set backspace=indent,eol,start " Better handling of backspace key
" have the h, l and cursor keys wrap between lines, as well as <Space> and
" <BackSpace>, and ~ convert case over line breaks; also have the cursor keys
" wrap in insert mode:
set whichwrap=b,s,h,l,~,<,>,[,]

set autoindent " Sane indenting when filetype not recognised
set nostartofline " Emulate typical editor navigation behaviour
set nopaste " Start in normal (non-paste) mode
set pastetoggle=<f11> " Use <F11> to toggle between 'paste' and 'nopaste'

" Status / Command Line Options:
set wildmenu " Better commandline completion
set wildmode=list:longest,full " Expand match on first Tab complete
set showcmd " Show (partial) command in status line.
set laststatus=2 " Always show a status line
set cmdheight=2 " Prevent "Press Enter" message after most commands
" Show detailed information in status line
"set statusline=%f%#error#%m%*%r%h%w\ [%n:%{&ff}/%Y]%=[0x\%04.4B][%03v][%p%%\ line\ %l\ of\ %L]
runtime stl_bloated.vim
"set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [BUF=\#%n]\ [POS=%04l,%04v]\ [%p%%]\ [LEN=%L]
"set statusline=%f%m%r%h%w\ [%n:%{&ff}/%Y]%=[0x\%04.4B][%03v][%p%%\ line\ %l\ of\ %L]

" Interface Options:
"set background=dark "Use a dark background
set number " Display line numbers at left of screen
set visualbell " Flash the screen instead of beeping on errors
set t_vb= " And then disable even the flashing
set mouse=a " Enable mouse usage (all modes) in terminals
" Quickly time out on keycodes, but never time out on mappings
set notimeout ttimeout ttimeoutlen=200

" Indentation Options:
set tabstop=8 " NEVER change this!
" Change the '2' value below to your preferred indentation level
set shiftwidth=2 softtabstop=2 " Number of spaces for each indent level
set expandtab " Even when pressing <Tab>

"""""""
" Maps
"""""""
"
" F1 to be a context sensitive keyword-under-cursor lookup
nnoremap <F1> :help <C-R><C-W><CR>

" Reformat current paragraph
nnoremap Q gq}

" Move cursor between visual lines on screen
nnoremap <Up> gk
nnoremap <Down> gj

" Map Y to act like D and C, i.e. to yank until EOL, rather than act as yy,
" which is the default
map Y y$

" Map <C-L> (redraw screen) to also turn off search highlighting until the
" next search
nnoremap <C-L> :nohl<CR><C-L>

" Toggle search highlighting
nnoremap <C-Bslash> :set hls!<bar>:set hls?<CR>
inoremap <C-Bslash> <Esc>:set hls!<bar>:set hls?<CR>a

""""""""""""""""
" Auto commands
""""""""""""""""
"
if has("autocmd")
  augroup vimrc
    " Remove ALL autocommands for the current group.
    autocmd!

    " Enable omni-completion by default
    if has("autocmd") && exists("+omnifunc")
        autocmd Filetype *
                \   if &omnifunc == "" |
                \       setlocal omnifunc=syntaxcomplete#Complete |
                \   endif
    endif

    " Enable extended % matching
    au VimEnter * au FileType * if !exists("b:match_words")
            \ | let b:match_words = &matchpairs | endif

    " Jump to last-known-position when editing files
    " Note: The | character is used in Vim as a command separator (like ; in C)
    au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
  augroup END
endif

""""""""""""
" Functions
""""""""""""
"
function! MyFoldText()
    let line = getline(v:foldstart)
    let sub = substitute(line, '/\*\|\*/\|{{{\d\=', '', 'g')
    return v:folddashes . sub
endfunction

"""""""""""""""""""
" Plugins settings
"""""""""""""""""""

" Enable extended % matching
runtime macros/matchit.vim
