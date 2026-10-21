syntax enable

set mouse=a
set ttymouse=sgr 

" Enable search highlighting
set hlsearch
set incsearch

set nobackup
set noswapfile
set re=0
set ignorecase
set smartcase

set clipboard^=unnamed,unnamedplus

if ! &insertmode
	set number
	set relativenumber
endif


" Highlight the current search match differently from other matches
" IncSearch: highlight during incremental search (the match you're typing)
" Search: highlight all matches
highlight IncSearch ctermbg=Yellow ctermfg=Black guibg=Yellow guifg=Black
highlight Search ctermbg=DarkGray ctermfg=White guibg=DarkGray guifg=White

" Ctrl + f to begin searching
inoremap <c-f> <c-o>/

" Ctl + f (x2) to stop highlighting the search results
inoremap <c-f>f <c-o>:nohlsearch<cr>
inoremap <c-f><c-f> <c-o>:nohlsearch<cr>

" F3 go to the previous match
inoremap <c-p> <c-o>:normal Nzz<cr>

" F4 go to the next match
inoremap <c-n> <c-o>:normal nzz<cr>

" Ctrl + h begin a search and replace
inoremap <c-h> <c-o>:%s///gc<Left><Left><Left><Left>

" Ctrl + x to delete current line
nnoremap <c-x> dd
inoremap <c-x> <c-o>dd

" Ctrl + d to duplicate current line
nnoremap <c-d> yyp
inoremap <c-d> <C-o>:normal yyp<CR>

" Ctrl + a to select all
nnoremap <c-a> ggVG
inoremap <c-a> <Esc>ggVG
