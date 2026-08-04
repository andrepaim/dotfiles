" ╔══════════════════════════════════════════════════════════════╗
" ║  .vimrc — General Coding Config (Tokyo Night)              ║
" ╚══════════════════════════════════════════════════════════════╝

" ── vim-plug Bootstrap ──────────────────────────────────────────
let s:plug_path = expand('~/.vim/autoload/plug.vim')
if empty(glob(s:plug_path)) && executable('curl')
  silent execute '!curl -fLo ' . s:plug_path . ' --create-dirs '
    \ . 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
endif

" ── Plugins ─────────────────────────────────────────────────────
if filereadable(s:plug_path)
  call plug#begin('~/.vim/plugged')

  " Colorscheme
  Plug 'ghifarit53/tokyonight-vim'

  " Fuzzy finder (installs fzf binary via do hook)
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'

  " Editing
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-sleuth'
  Plug 'jiangmiao/auto-pairs'

  " Git
  Plug 'tpope/vim-fugitive'

  " Linting
  Plug 'dense-analysis/ale'

  call plug#end()

  if empty(glob('~/.vim/plugged/*'))
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
  endif
endif

" ── General ─────────────────────────────────────────────────────
set nocompatible
filetype plugin indent on
syntax on
set encoding=utf-8
set fileencoding=utf-8
set hidden
set autoread
set nobackup
set nowritebackup
set noswapfile
set updatetime=250
set timeoutlen=500
set mouse=a
set backspace=indent,eol,start
set nrformats-=octal
set history=1000

" ── Persistent Undo ─────────────────────────────────────────────
let s:undodir = expand('~/.vim/undodir')
if !isdirectory(s:undodir)
  call mkdir(s:undodir, 'p')
endif
set undofile
let &undodir = s:undodir

" ── Display ─────────────────────────────────────────────────────
set number
set relativenumber
set cursorline
set signcolumn=yes
set scrolloff=8
set sidescrolloff=8
set colorcolumn=80
set showmatch
set laststatus=2
set noshowmode
set showcmd
set ruler
set wrap
set linebreak
set display+=lastline

" ── True Color (with tmux fix) ──────────────────────────────────
if has('termguicolors')
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

" ── Colorscheme ─────────────────────────────────────────────────
set background=dark
try
  let g:tokyonight_style = 'night'
  let g:tokyonight_enable_italic = 1
  colorscheme tokyonight
catch
  try
    colorscheme tokyonight_custom
  catch
    colorscheme desert
  endtry
endtry

" ── Indentation (default 2-space, vim-sleuth auto-detects) ──────
set expandtab
set tabstop=2
set shiftwidth=2
set softtabstop=2
set smartindent
set autoindent
set shiftround

" ── Search ──────────────────────────────────────────────────────
set incsearch
set hlsearch
set ignorecase
set smartcase

" ── Wildmenu Completion ─────────────────────────────────────────
set wildmenu
set wildmode=longest:full,full
set wildignore+=*.o,*.obj,*.pyc,*.pyo,*/__pycache__/*
set wildignore+=*.swp,*~,*.tmp
set wildignore+=.git/*,.hg/*,.svn/*
set wildignore+=node_modules/*,vendor/*,target/*
set wildignore+=*.png,*.jpg,*.gif,*.ico

" ── Splits ──────────────────────────────────────────────────────
set splitbelow
set splitright

" ── System Clipboard ────────────────────────────────────────────
if has('clipboard')
  set clipboard=unnamedplus
elseif executable('clip.exe') || executable('pbcopy')
      \ || executable('wl-copy') || executable('xclip')
      \ || executable('xsel')
  function! CopyToSystemClipboard(value) abort
    if executable('clip.exe')
      call system('clip.exe', a:value)
    elseif executable('pbcopy')
      call system('pbcopy', a:value)
    elseif executable('wl-copy')
      call system('wl-copy', a:value)
    elseif executable('xclip')
      call system('xclip -selection clipboard -in', a:value)
    elseif executable('xsel')
      call system('xsel --clipboard --input', a:value)
    endif
  endfunction

  augroup SystemClipboard
    autocmd!
    autocmd TextYankPost * if v:event.operator ==# 'y'
      \ | call CopyToSystemClipboard(getreg(v:event.regname))
      \ | endif
  augroup END
endif

" ── Leader Key ──────────────────────────────────────────────────
let mapleader = ' '
let maplocalleader = ' '

" ── General Mappings ────────────────────────────────────────────
" Quick save / quit
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>

" Clear search highlight
nnoremap <leader><space> :nohlsearch<CR>

" Escape from insert mode
inoremap jk <Esc>

" Buffer navigation
nnoremap <Tab> :bnext<CR>
nnoremap <S-Tab> :bprevious<CR>

" Window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Window resizing
nnoremap <C-Up>    :resize +2<CR>
nnoremap <C-Down>  :resize -2<CR>
nnoremap <C-Left>  :vertical resize -2<CR>
nnoremap <C-Right> :vertical resize +2<CR>

" Move selection up/down in visual mode
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

" Indent and keep selection
vnoremap < <gv
vnoremap > >gv

" Keep cursor centered on search navigation
nnoremap n nzzzv
nnoremap N Nzzzv

" ── fzf Mappings ────────────────────────────────────────────────
nnoremap <leader>ff :Files<CR>
nnoremap <leader>fb :Buffers<CR>
nnoremap <leader>fg :Rg<CR>
nnoremap <leader>fh :History<CR>
nnoremap <C-p>      :Files<CR>

" fzf layout
let g:fzf_layout = { 'down': '40%' }

" ── Git (Fugitive) Mappings ─────────────────────────────────────
nnoremap <leader>gs :Git<CR>
nnoremap <leader>gb :Git blame<CR>
nnoremap <leader>gd :Gdiffsplit<CR>
nnoremap <leader>gl :Git log --oneline -20<CR>

" ── Netrw File Explorer ─────────────────────────────────────────
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_winsize = 25
nnoremap <leader>e :Lexplore<CR>

" ── ALE Configuration ───────────────────────────────────────────
let g:ale_linters_explicit = 1
let g:ale_linters = {}
let g:ale_fix_on_save = 0
let g:ale_sign_error = 'E'
let g:ale_sign_warning = 'W'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
let g:ale_virtualtext_cursor = 'disabled'

" ALE diagnostic navigation
nnoremap ]d :ALENextWrap<CR>
nnoremap [d :ALEPreviousWrap<CR>

" ── Statusline ──────────────────────────────────────────────────
" Palette (matching tmux)
let s:sl_bg_dark  = '#1a1b26'
let s:sl_bg_mid   = '#24283b'
let s:sl_bg_light = '#414868'
let s:sl_fg       = '#a9b1d6'
let s:sl_blue     = '#7aa2f7'
let s:sl_green    = '#9ece6a'
let s:sl_purple   = '#bb9af7'
let s:sl_yellow   = '#e0af68'
let s:sl_red      = '#f7768e'
let s:sl_cyan     = '#7dcfff'

function! StatuslineMode() abort
  let l:mode = mode()
  if     l:mode ==# 'n'  | return 'NORMAL'
  elseif l:mode ==# 'i'  | return 'INSERT'
  elseif l:mode ==# 'R'  | return 'REPLACE'
  elseif l:mode ==# 'v'  | return 'VISUAL'
  elseif l:mode ==# 'V'  | return 'V-LINE'
  elseif l:mode ==# "\<C-V>" | return 'V-BLOCK'
  elseif l:mode ==# 'c'  | return 'COMMAND'
  elseif l:mode ==# 't'  | return 'TERMINAL'
  else                    | return 'OTHER'
  endif
endfunction

function! StatuslineModeColor() abort
  let l:mode = mode()
  if     l:mode ==# 'i'       | return '%#StatusInsert#'
  elseif l:mode ==# 'R'       | return '%#StatusReplace#'
  elseif l:mode =~# '[vV\x16]' | return '%#StatusVisual#'
  elseif l:mode ==# 'c'       | return '%#StatusCommand#'
  else                         | return '%#StatusNormal#'
  endif
endfunction

function! StatuslineGitBranch() abort
  if exists('*FugitiveHead')
    let l:branch = FugitiveHead()
    return l:branch !=# '' ? '  ' . l:branch . ' ' : ''
  endif
  return ''
endfunction

function! SetupStatuslineColors() abort
  exec 'hi StatusNormal  guifg=' . s:sl_bg_dark . ' guibg=' . s:sl_blue   . ' gui=bold'
  exec 'hi StatusInsert  guifg=' . s:sl_bg_dark . ' guibg=' . s:sl_green  . ' gui=bold'
  exec 'hi StatusVisual  guifg=' . s:sl_bg_dark . ' guibg=' . s:sl_purple . ' gui=bold'
  exec 'hi StatusReplace guifg=' . s:sl_bg_dark . ' guibg=' . s:sl_yellow . ' gui=bold'
  exec 'hi StatusCommand guifg=' . s:sl_bg_dark . ' guibg=' . s:sl_red    . ' gui=bold'
  exec 'hi StatusBranch  guifg=' . s:sl_green   . ' guibg=' . s:sl_bg_mid . ' gui=NONE'
  exec 'hi StatusFile    guifg=' . s:sl_fg      . ' guibg=' . s:sl_bg_mid . ' gui=NONE'
  exec 'hi StatusMid     guifg=' . s:sl_bg_light . ' guibg=' . s:sl_bg_dark . ' gui=NONE'
  exec 'hi StatusRight   guifg=' . s:sl_fg      . ' guibg=' . s:sl_bg_mid . ' gui=NONE'
  exec 'hi StatusPos     guifg=' . s:sl_bg_dark . ' guibg=' . s:sl_blue   . ' gui=bold'
endfunction

call SetupStatuslineColors()

function! BuildStatusline() abort
  let l:s  = '%{%StatuslineModeColor()%}'
  let l:s .= ' %{StatuslineMode()} '
  let l:s .= '%#StatusBranch#'
  let l:s .= '%{StatuslineGitBranch()}'
  let l:s .= '%#StatusFile#'
  let l:s .= ' %f %m%r'
  let l:s .= '%#StatusMid#'
  let l:s .= '%='
  let l:s .= '%#StatusRight#'
  let l:s .= ' %{&filetype} '
  let l:s .= '%#StatusPos#'
  let l:s .= ' %l:%c | %p%% '
  return l:s
endfunction

set statusline=%!BuildStatusline()

" Refresh statusline colors on colorscheme change
augroup StatuslineColors
  autocmd!
  autocmd ColorScheme * call SetupStatuslineColors()
augroup END

" ── Autocommands ────────────────────────────────────────────────
augroup GeneralAutocommands
  autocmd!

  " Return to last edit position on file open
  autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$")
    \ |   execute "normal! g'\""
    \ | endif

  " Auto-resize splits on terminal resize
  autocmd VimResized * wincmd =

  " Filetype-specific indentation
  autocmd FileType python     setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab
  autocmd FileType go         setlocal tabstop=4 shiftwidth=4 softtabstop=4 noexpandtab
  autocmd FileType rust       setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab
  autocmd FileType make       setlocal tabstop=8 shiftwidth=8 softtabstop=0 noexpandtab

  " Markdown and text: soft wrap
  autocmd FileType markdown,text setlocal wrap linebreak spell

augroup END
