" Number of spaces that a pre-existing tab is equal to.
" For the amount of space used for a new tab use shiftwidth.
au BufRead,BufNewFile *py,*pyw,*.c,*.h set tabstop=8

" What to use for an indent.
" This will affect Ctrl-T and 'autoindent'.
" Python: 4 spaces
" C: 4 spaces
au BufRead,BufNewFile *.c,*.h,*.py,*pyw set shiftwidth=4
au BufRead,BufNewFile *.c,*.h,*.py,*.pyw set expandtab
au BufRead,BufNewFile Makefile* set noexpandtab

" Use the below highlight group when displaying bad whitespace is desired.
highlight BadWhitespace ctermbg=darkred guibg=darkred

" Display tabs at the beginning of a line in Python mode as bad.
au BufRead,BufNewFile *.py,*.pyw match BadWhitespace /^\t\+/
" Make trailing whitespace be flagged as bad.
au BufRead,BufNewFile *.py,*.pyw,*.c,*.cpp,*.h match BadWhitespace /\s\+$/

" Use UNIX (\n) line endings.
" Only used for new files so as to not force existing files to change their
" line endings.
" Python: yes
" C: yes
au BufNewFile *.py,*.pyw,*.c,*.h set fileformat=unix

" Set the default file encoding to UTF-8:
set encoding=utf-8
" Puts a marker at the beginning of the file to differentiate between UTF and
" UCS encoding (WARNING: can trick shells into thinking a text file is actually
" a binary file when executing the text file): ``set bomb``

" Automatically indent based on file type: 
filetype indent on

"" Folding
set foldmethod=indent   "Set folding based on indentation
"highlight Folded guibg=brown guifg=blue
"highlight FoldColumn guibg=darkgrey guifg=white

" For full syntax highlighting:
let python_highlight_all=1
syntax on

"" General
set number	        " Show line numbers
set linebreak           " Break lines at word
set showbreak=+++ 	" Wrap-broken line prefix
set textwidth=100	" Line wrap (number of cols)
set showmatch	        " Highlight matching brace
 
set hlsearch	        " Highlight all search results
set smartcase	        " Enable smart-case search
set ignorecase	        " Always case-insensitive
set incsearch	        " Searches for strings incrementally
 
set autoindent	        " Auto-indent new lines
set expandtab	        " Use spaces instead of tabs
set shiftwidth=4	" Number of auto-indent spaces
set smartindent	        " Enable smart-indent
"set smarttab	        " Enable smart-tabs
set softtabstop=4	" Number of spaces per Tab
 
"" Advanced
set ruler	        " Show row and column ruler information
 
set undolevels=255      " Number of undo levels
set backspace=indent,eol,start

"" Easy unhighlight
nnoremap nh :noh<CR>

"" Tabs
nnoremap <C-t>     :tabnew<CR>
nnoremap tl  :tabnext<CR>
nnoremap th  :tabprev<CR>
nnoremap tL  :tablast<CR>
nnoremap te  :tabedit<Space>
nnoremap tm  :tabm<Space>
nnoremap td  :tabclose<CR>

"" Misc
colorscheme desert

"" Reselect visual block after indent/dedent
vnoremap < <gv
vnoremap > >gv

"" Move down wrapped lines
nnoremap j gj
nnoremap k gk

"" No sudo vim pls
cmap w!! %!sudo tee > /dev/null %

"" Easy hex
cmap hex %! xxd
cmap nohex %! xxd -r

"" Dragging lines
nnoremap <C-j> :m+<CR>
nnoremap <C-k> :m-2<CR>

"" Paste toggle
set pastetoggle=<F8> "enable paste toggle and map it to F8

"" Run python code on F5
"" map <f5> :w <CR>!clear <CR>:!python % <CR>

"" Highlight in red lines that are too long
augroup vimrc_autocmds
  autocmd BufEnter * highlight OverLength ctermbg=darkgrey "ctermfg=darkred
  autocmd BufEnter * match OverLength /\%79v.*/
augroup END
