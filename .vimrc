syntax enable
filetype plugin indent on

let mapleader = " "

" --- options (from nvim/lua/options.lua) ---
set number
set relativenumber
set cursorline
highlight CursorLine cterm=NONE ctermbg=236 guibg=#2a2a2a
set mouse=a
set ttymouse=sgr
set clipboard^=unnamed,unnamedplus
set ignorecase
set smartcase
set hlsearch
set incsearch
set splitright
set splitbelow
set noswapfile
set nobackup
set undofile
set autoread
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab
set smartindent
set wrap
set linebreak
set laststatus=2
set re=0

if exists('+termguicolors')
  set termguicolors
endif
if exists('+signcolumn')
  set signcolumn=yes
endif
if exists('+pumheight')
  set pumheight=12
endif

set completeopt=menu,menuone,noselect
set wildmenu

" --- netrw (from nvim/lua/netrw.lua) ---
let g:netrw_liststyle = 3
let g:netrw_banner = 0
let g:netrw_altfile = 1

function! s:ToggleExplore() abort
  if &filetype ==# 'netrw'
    buffer #
  else
    Explore
  endif
endfunction

nnoremap <silent> <leader>e :call <SID>ToggleExplore()<CR>

" --- keymaps (from nvim/lua/keymaps.lua) ---
nnoremap <silent> <leader>p "+p
inoremap <silent> <M-BS> <C-W>
nnoremap <silent> <Esc> :nohlsearch<CR><Esc>
nnoremap Q <Nop>

nnoremap <leader>sr :%s///g<Left><Left><Left>
xnoremap <leader>sr :s///g<Left><Left><Left>
nnoremap <silent> ZX :qa!<CR>

nnoremap <silent> <C-u> <C-u>zz
nnoremap <silent> <C-d> <C-d>zz
nnoremap <silent> <C-f> <C-f>zz
nnoremap <silent> <C-b> <C-b>zz
nnoremap n nzzzv
nnoremap N Nzzzv

nnoremap <silent> ]x /<<<<<<<CR>
nnoremap <silent> [x ?<<<<<<<CR>

vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

nnoremap =ap ma=ap'a

" --- macros (from nvim/lua/options.lua) ---
let @l = "yoconsole.log('\<Esc>pa: '\<Esc>a, \<Esc>pa)\<Esc>l"

" --- autocmds (from nvim/lua/autocommands.lua + options.lua) ---
augroup vimrc
  autocmd!
  autocmd FileType qf setlocal wrap linebreak
  autocmd BufReadPost *
        \ if line("'\"") >= 1 && line("'\"") <= line('$') |
        \   execute 'normal! g`"zz' |
        \ endif
augroup END

" Conflict markers for % / matchit when available.
if !exists('g:loaded_matchit') && findfile('macros/matchit.vim', &rtp) !=# ''
  runtime macros/matchit.vim
endif
augroup vimrc_conflict_match
  autocmd!
  autocmd FileType * call s:AddConflictMatchWords()
augroup END

function! s:AddConflictMatchWords() abort
  let l:words = '^<<<<<<<.*:^=======.*:^>>>>>>>.*'
  if exists('b:match_words') && b:match_words !=# ''
    if stridx(b:match_words, l:words) < 0
      let b:match_words .= ',' . l:words
    endif
  else
    let b:match_words = l:words
  endif
endfunction
