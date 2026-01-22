" <<<
" Security: disable automatic sourcing of local vimrc files
set noexrc
set secure

" Use bash as shell (needed for Guix environments where /bin/sh doesn't exist)
if executable('bash')
  set shell=bash
endif

" Install plug.vim, if not installed.
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
let plug_installed = !empty(glob(data_dir . '/autoload/plug.vim'))
if !plug_installed
  " Try to install vim-plug (only works if network is available)
  silent! execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  let plug_installed = !empty(glob(data_dir . '/autoload/plug.vim'))
  if plug_installed
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
  endif
endif

" Only load plugins if vim-plug is available
if plug_installed
  call plug#begin()
Plug 'vimwiki/vimwiki'
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Markdown stuff
Plug 'godlygeek/tabular' | Plug 'plasticboy/vim-markdown'
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}

Plug 'junegunn/limelight.vim'
Plug 'junegunn/goyo.vim'

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'ludovicchabant/vim-gutentags'

Plug 'preservim/nerdtree'
"Plug 'ryanoasis/vim-devicons'
"Plug 'Xuyuanp/nerdtree-git-plugin'
"Plug 'tiagofumo/vim-nerdtree-syntax-highlight'

Plug 'rust-lang/rust.vim'
Plug 'dense-analysis/ale'

" colors
Plug 'morhetz/gruvbox'
Plug 'haishanh/night-owl.vim'
Plug 'cocopon/iceberg.vim'
  call plug#end()
endif

" rustfmt configuration
let g:rustfmt_autosave = 0
let g:rustfmt_emit_files = 1
let g:rustfmt_fail_silently = 0

" vimwiki config
let g:vimwiki_list = [{'path': '~/Documents/wikis/vimwiki/', 'syntax': 'markdown', 'ext': '.md'},
                    \ {'path': '~/Documents/wikis/shadowmaze/', 'syntax': 'markdown', 'ext': '.md'},
                    \ {'path': '~/Documents/wikis/echowiki/', 'syntax': 'markdown', 'ext': '.md'}]
" Done installing plugins.
" >>>

" Use Vim settings, rather than Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible

" If using a dark background within the editing area and syntax highlighting
" turn on this option as well
set background=dark

" The following are commented out as they cause vim to behave a lot
" differently from regular Vi. They are highly recommended though.
set showcmd " Show (partial) command in status line.
set showmatch " Show matching brackets.
set incsearch " Incremental search
"set ignorecase " Do case insensitive matching
"set smartcase " Do smart case matching
"set autowrite " Automatically save before commands like :next and :make
"set hidden " Hide buffers when they are abandoned
"set mouse=a " Enable mouse usage (all modes)

" Source a global configuration file if available
if filereadable("/etc/vim/vimrc.local")
 source /etc/vim/vimrc.local
endif

"set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [ASCII=\%03.3b]\ [HEX=\%02.2B]\ [POS=%04l,%04v][%p%%]\ [LEN=%L]
"
"" Tell vim to remember certain things when we exit
"" " '10 : marks will be remembered for up to 10 previously edited files
"" " "100 : will save up to 100 lines for each register
"" " :20 : up to 20 lines of command-line history will be remembered
"" " % : saves and restores the buffer list
"" " n... : where to save the viminfo files
set viminfo='10,\"100,:50,%,n~/.viminfo
"
""restores cursor position
"function! ResCur()
" if line("'\"") <= line("$")
" normal! g`"
" return 1
" endif
"endfunction
"
"augroup resCur
" autocmd!
" autocmd BufWinEnter * call ResCur()
"augroup END

set expandtab
set ts=4
set ai

" If you have vim >=8.0 or Neovim >= 0.1.5
if (has("termguicolors"))
 set termguicolors
endif

"colorscheme elflord
"let g:gruvbox_contrast_dark = "hard"
"colorscheme gruvbox
"colorscheme night-owl
" Only set colorscheme if it's available (requires vim-plug plugins)
silent! colorscheme iceberg

set sw=4
set sts=4

set ruler
set cindent
filetype plugin on
filetype indent on
"set number
set fo+=t
set omnifunc=syntaxcomplete#Complete

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

if has("vms")
 set nobackup " do not keep a backup file, use versions instead
else
 set backup " keep a backup file (restore to previous version)
 set undodir=~/.vim/backup//,/var/tmp//,/tmp//,.
 set undofile " keep an undo file (undo changes after closing)
endif

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
 syntax on
 set hlsearch
endif


" Only do this part when compiled with support for autocommands.
if has("autocmd")

 " Enable file type detection.
 " Use the default filetype settings, so that mail gets 'tw' set to 72,
 " 'cindent' is on in C files, etc.
 " Also load indent files, to automatically do language-dependent indenting.
 filetype plugin indent on

 " Put these in an autocmd group, so that we can delete them easily.
 augroup vimrcEx
 au!

 " For all text files set 'textwidth' to 120 characters.
 "autocmd FileType text setlocal textwidth=120
 autocmd FileType text setlocal textwidth=89

 " When editing a file, always jump to the last known cursor position.
 " Don't do it when the position is invalid or when inside an event handler
 " (happens when dropping a file on gvim).
 " Also don't do it when the mark is in the first line, that is the default
 " position when opening a file.
 autocmd BufReadPost *
 \ if line("'\"") > 1 && line("'\"") <= line("$") |
 \ exe "normal! g`\"" |
 \ endif

 augroup END

else

 set autoindent " always set autoindenting on

endif " has("autocmd")


set splitbelow
set splitright
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" elguapo: Trying a colorcolumn again.
" "highlight anything over 120 characters
" "To turn off:
" "  :noautocmd match
" highlight OverLength ctermbg=DarkGrey ctermfg=white guibg=#592929
" autocmd VimEnter,WinEnter * match OverLength /\%81v.\+/

" Use the X/Wayland system clipboard by default
set clipboard=unnamedplus

"highlight trailing whitespace
highlight whiteSpace_trailing ctermbg=DarkGrey guibg=red
augroup trailing_whitespace
    autocmd!
    autocmd VimEnter,WinEnter,InsertLeave * 2match whiteSpace_trailing /\s\+$/
    autocmd InsertEnter * 2match whiteSpace_trailing /\s\+\%#\@<!$/
augroup END

""""if &term =~ '^xterm'
""""if &term =~ "xterm"
"""" " t_SI start insert mode (bar cursor shape)
"""" " t_EI end insert mode (block cursor shape)
"""" " solid underscore
"""" let &t_SI .= "\<Esc>[4 q"
""""
"""" " solid block
"""" let &t_EI .= "\<Esc>[0 q"
"""" " 2 -> solid block
"""" " 1 or 0 -> blinking block
"""" " 3 -> blinking underscore
"""" "let &t_SI = "\<Esc>]12;purple\x7"
"""" "let &t_EI = "\<Esc>]12;blue\x7"
""""endif
""""
""""xterm or mintty foo... shenanigans!
"""if &term =~ '^xterm'
""" let &t_SI .= "\<Esc>[4 q"
""" let &t_EI .= "\<Esc>[1 q"
"""
""" "let &t_ti.="\e[1 q"
""" "let &t_SI.="\e[5 q"
""" "let &t_EI.="\e[1 q"
""" "let &t_te.="\e[0 q"
"""endif

if $COLORTERM=~'xfce4-terminal' && has("autocmd")
 au InsertEnter * silent execute "!sed -i.bak -e 's/TERMINAL_CURSOR_SHAPE_BLOCK/TERMINAL_CURSOR_SHAPE_UNDERLINE/' ~/.config/xfce4/terminal/terminalrc"
 au InsertLeave * silent execute "!sed -i.bak -e 's/TERMINAL_CURSOR_SHAPE_UNDERLINE/TERMINAL_CURSOR_SHAPE_BLOCK/' ~/.config/xfce4/terminal/terminalrc"
 au VimLeave * silent execute "!sed -i.bak -e 's/TERMINAL_CURSOR_SHAPE_UNDERLINE/TERMINAL_CURSOR_SHAPE_BLOCK/' ~/.config/xfce4/terminal/terminalrc"
endif "xterm

" timestamp in backup file name
au BufWritePre * let &bex = '-' . strftime("%Y%m%d-%H%M%S") . '.vimbackup'

" Put backup and temp files here...
set backupdir=~/.vim/backup//,/var/tmp//,/tmp//,.
set directory=~/.vim/backup//,/var/tmp//,/tmp//,.

" Move up and down in autocomplete with <c-j> and <c-k>
inoremap <expr> <c-j> ("\<C-n>")
inoremap <expr> <c-k> ("\<C-p>")

set matchpairs+=<:>

set tabstop=4
set shiftwidth=4

" Define key map for trimming whitespace: \w
fun! TrimWhitespace()
    let l:save = winsaveview()
    keeppatterns %s/\s\+$//e
    call winrestview(l:save)
endfun
noremap <Leader>w :call TrimWhitespace()<CR>

" Only load coc config if coc.nvim is available
if plug_installed && filereadable("/home/dennis/.vim/coc-config.vim")
 source ~/.vim/coc-config.vim
endif
" Only load markdown-preview config if plugins are available
if plug_installed && filereadable("/home/dennis/.vim/markdown-preview.vim")
 source /home/dennis/.vim/markdown-preview.vim
endif


" Line numbers and relative line numbers.
nnoremap <leader>nr :set relativenumber!<cr>
nnoremap <leader>na :set number!<cr>
nnoremap <leader>nn :set number! relativenumber!<cr>
" Set/clear colorcolumn
nnoremap <leader>sc :set colorcolumn=81<cr>
nnoremap <leader>cc :set colorcolumn=<cr>

" delete me!
"set signcolumn="no"
"set number! relativenumber!

set tags=tags;/
autocmd BufRead *.rs :setlocal tags=./rusty-tags.vi;/
autocmd BufWritePost *.rs :silent! exec "!rusty-tags vi --quiet --start-dir=" . expand('%:p:h') . "&" | redraw!

" buffer navigation
nnoremap <Leader>h :bprevious<CR>
nnoremap <Leader>l :bnext<CR>
nnoremap <Leader>k :bfirst<CR>
nnoremap <Leader>j :blast<CR>

" fzf and ripgrep mappings
nnoremap <C-i> :Files<CR>
nnoremap <C-p> :Rg<CR>

" NERDTree stuff
nnoremap <C-n> :NERDTreeToggle<CR>
" Start NERDTree when Vim is started without file arguments (only if plugins available).
if plug_installed
  autocmd StdinReadPre * let s:std_in=1
  autocmd VimEnter * if argc() == 0 && !exists('s:std_in') | NERDTree | endif

  " Keep language diagnostics off by default; toggle when needed.
  let g:ale_enabled = 0
  augroup diagnostics_off
    autocmd!
    autocmd VimEnter * silent! CocDisable
  augroup END
  nnoremap <leader>ae :ALEEnable<CR>
  nnoremap <leader>ad :ALEDisable<CR>
  nnoremap <leader>ce :CocEnable<CR>
  nnoremap <leader>cd :CocDisable<CR>
endif

" Turn on by default.
set number relativenumber
"set colorcolumn=81

" Customize diff-related colors (must come after the colorscheme command)
hi DiffAdd      gui=none    guifg=NONE          guibg=#bada9f
hi DiffChange   gui=none    guifg=NONE          guibg=#e5d5ac
hi DiffDelete   gui=bold    guifg=#ff8080       guibg=#ffb0b0
hi DiffText     gui=none    guifg=NONE          guibg=#8cbee2

" ## added by OPAM user-setup for vim / base ## 93ee63e278bdfc07d1139a748ed3fff2 ## you can edit, but keep this line
let s:opam_share_dir = system("opam config var share")
let s:opam_share_dir = substitute(s:opam_share_dir, '[\r\n]*$', '', '')

let s:opam_configuration = {}

function! OpamConfOcpIndent()
  execute "set rtp^=" . s:opam_share_dir . "/ocp-indent/vim"
endfunction
let s:opam_configuration['ocp-indent'] = function('OpamConfOcpIndent')

function! OpamConfOcpIndex()
  execute "set rtp+=" . s:opam_share_dir . "/ocp-index/vim"
endfunction
let s:opam_configuration['ocp-index'] = function('OpamConfOcpIndex')

function! OpamConfMerlin()
  let l:dir = s:opam_share_dir . "/merlin/vim"
  execute "set rtp+=" . l:dir
endfunction
let s:opam_configuration['merlin'] = function('OpamConfMerlin')

let s:opam_packages = ["ocp-indent", "ocp-index", "merlin"]
let s:opam_check_cmdline = ["opam list --installed --short --safe --color=never"] + s:opam_packages
let s:opam_available_tools = split(system(join(s:opam_check_cmdline)))
for tool in s:opam_packages
  " Respect package order (merlin should be after ocp-index)
  if count(s:opam_available_tools, tool) > 0
    call s:opam_configuration[tool]()
  endif
endfor
" ## end of OPAM user-setup addition for vim / base ## keep this line
" ## added by OPAM user-setup for vim / ocp-indent ## b29558e067cfbc178422d6e98461868c ## you can edit, but keep this line
if count(s:opam_available_tools,"ocp-indent") == 0
  let ocaml_indent_file = "/home/dennis/.opam/default/share/ocp-indent/vim/indent/ocaml.vim"
  if filereadable(ocaml_indent_file)
    source "/home/dennis/.opam/default/share/ocp-indent/vim/indent/ocaml.vim"
  endif
  unlet ocaml_indent_file
endif
" ## end of OPAM user-setup addition for vim / ocp-indent ## keep this line

" diable coc unless I want it (:CocEnable)
"let s:my_coc_file_types = ['c', 'cpp', 'h', 'asm', 'hpp', 'vim', 'sh', 'py']
"function! s:disable_coc_for_type()
"	"if index(g:my_coc_file_types, &filetype) == -1
"	"        let b:coc_enabled = 0
"	"endif
"    let b:coc_enabled = 0
"endfunction
"augroup CocGroup
"	autocmd!
"	autocmd BufNew,BufEnter * call s:disable_coc_for_type()
"augroup end

" elguapo:
"" CoC: {{{
"if exists('g:coc_enabled')
"  hi! CocErrorSign  ctermfg=blue guifg=#ff0000
"  hi CocInfoSign  ctermfg=black guifg=#fab005
"endif
" }}}
