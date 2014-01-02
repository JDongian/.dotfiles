"" Vundle
filetype off
set nocompatible
set rtp+=~/.vim/bundle/vundle
call vundle#rc()

Bundle 'gmarick/vundle'
Bundle 'scrooloose/syntastic'

filetype plugin indent on

let g:syntastic_python_checkers=['pylint', 'pep8']

" Set the default file encoding to UTF-8:
set encoding=utf-8
" Automatically indent based on file type: 
filetype indent on
"" Folding
set foldmethod=indent   "Set folding based on indentation
"highlight Folded guibg=brown guifg=blue
"highlight FoldColumn guibg=darkgrey guifg=white
set number	        " Show line numbers
set linebreak           " Break lines at word
set showbreak=+++ 	" Wrap-broken line prefix
set showmatch	        " Highlight matching brace
set hlsearch	        " Highlight all search results
set smartcase	        " Enable smart-case search
set ignorecase	        " Always case-insensitive
set incsearch	        " Searches for strings incrementally
set autoindent	        " Auto-indent new lines
set expandtab	        " Use spaces instead of tabs
set shiftwidth=4	" Number of auto-indent spaces
set smartindent	        " Enable smart-indent
set softtabstop=4	" Number of spaces per Tab
set ruler	        " Show row and column ruler information
set undolevels=1023      " Number of undo levels
set backspace=indent,eol,start

"" Easy unhighlight
nnoremap nh :noh<CR>

"" Run python code on F5
"" map <f5> :w <CR>!clear <CR>:!python % <CR>

"" Tab management
nnoremap <C-t>     :tabnew<CR>
nnoremap tl  :tabnext<CR>
nnoremap th  :tabprev<CR>
nnoremap tL  :tablast<CR>
nnoremap te  :tabedit<Space>
nnoremap tm  :tabm<Space>
nnoremap td  :tabclose<CR>

"" Reselect visual block after indent/dedent
vnoremap < <gv
vnoremap > >gv

"" Move down wrapped lines intutively
nnoremap j gj
nnoremap k gk

"" w!! saves as sudo
cmap w!! w !sudo tee %

"" Easy hex
cmap hex %! xxd
cmap unhex %! xxd -r

"" DOS/UNIX filetype switch for ^M line endings
cmap dosfile ed ++ff=dos %
cmap unixfile ed ++ff=unix %

"" Dragging lines
nnoremap <C-j> :m+<CR>
nnoremap <C-k> :m-2<CR>

"" F8 toggles paste mode
set pastetoggle=<F8> 

"" netrw config to emulate NERDtree
" Toggle Vexplore with Ctrl-E
function! ToggleVExplorer()
  if exists("t:expl_buf_num")
      let expl_win_num = bufwinnr(t:expl_buf_num)
      if expl_win_num != -1
          let cur_win_nr = winnr()
          exec expl_win_num . 'wincmd w'
          close
          exec cur_win_nr . 'wincmd w'
          unlet t:expl_buf_num
      else
          unlet t:expl_buf_num
      endif
  else
      exec '1wincmd w'
      Vexplore
      let t:expl_buf_num = bufnr("%")
  endif
endfunction
map <silent> <C-E> :call ToggleVExplorer()<CR>
" Hit enter in the file browser to open the selected
" file with :vsplit to the right of the browser.
let g:netrw_browse_split = 4
let g:netrw_altv = 1
" Default to tree mode
let g:netrw_liststyle=3
" Change directory to the current buffer when opening files.
set autochdir

"" Colorscheme
let python_highlight_all=1
syntax enable
set background=dark
colorscheme desert

au BufRead,BufNewFile *.c,*.h,*.py,*.pyw set expandtab
au BufRead,BufNewFile Makefile* set noexpandtab
" Use the below highlight group when displaying bad whitespace is desired.
highlight BadWhitespace ctermbg=darkred guibg=darkred
" Display tabs at the beginning of a line in Python mode as bad.
au BufRead,BufNewFile *.py,*.pyw,*.c,*.cpp,*.h match BadWhitespace /^\t\+/
" Make trailing whitespace be flagged as bad.
au BufRead,BufNewFile *.py,*.pyw,*.c,*.cpp,*.h match BadWhitespace /\s\+$/

"" Overlength highlighting (>79 chars)
augroup vimrc_autocmds
  autocmd BufEnter * highlight OverLength ctermbg=darkgrey "ctermfg=darkred
  autocmd BufEnter * match OverLength /\%79v.*/
