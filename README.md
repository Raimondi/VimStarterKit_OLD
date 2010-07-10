Extended feature to original pathogen
======================================
First Look following example of .vimrc.  
These setting shold be placed head of .vimrc.  

    " pathogen#init() difines DisablePlugin command.
    " this command acccept one or more `directory` name under 'bundle'
    call pathogen#init()

    " avoid loading plugin depending on 'gui_macvim' feature
    if has('gui_macvim')
       DisablePlugin neocomplcache
    else
       DisablePlugin autocomplpop
    endif

    DisablePlugin rails
    "DisablePlugin unimpaired

    " finally add plugin dir(except disabled one) under 'bundle' to &rtp.
    call pathogen#runtime_append_all_bundles()

Useful scenario
======================================
Test several plugin.  
Easly disable,enable pluign whitiout moving directory from under bundle.  

## Following example a bit dirty hack but work.
You can move plugin specific configuration under each plugin dir with pathogeon.  
With convination of DisablePlugin command, only when you didn't disabled plugin , the plugin specific configuration is loaded.  
This hack simplify comment in/out and check g:loaded_plugname flug for each plugin.  

In following example take arpeggio plugin  as example.  
When you didn't disalbed arpeggio `1_CONFIG.vim` and `arpeggio.vim` is  
loaded. you can set any arpeggio specific configuration in `1_CONFIG.vim` .  
The reason name `1_CONFIG.vim` is used is for ensureing loaded before each main plugin is loaded.  

    | |~arpeggio/
    | | |~after/
    | | | `+syntax/
    | | |+autoload/
    | | |+doc/
    | | |~plugin/
    | | | |-1_CONFIG.vim
    | | | `-arpeggio.vim

