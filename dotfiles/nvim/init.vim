colorscheme vim

filetype plugin indent on

set foldmethod=indent
autocmd InsertLeave * set nopaste

set expandtab
set ignorecase
set incsearch
set linebreak
set number
set shiftwidth=4
set showbreak=+++
set smartcase
set smartindent
set softtabstop=4
set timeoutlen=200

" Tab management
nnoremap nh :noh<cr>
nnoremap <C-t>  :tabnew<CR>
nnoremap te     :tabedit<Space>
nnoremap tl     :tabnext<CR>
nnoremap th     :tabprev<CR>
nnoremap tL     :tablast<CR>
nnoremap tm     :tabm<Space>
nnoremap td     :tabclose<CR>

" Reselect visual block after indent/dedent
vnoremap < <gv
vnoremap > >gv

" Open man page for word under cursor
nnoremap ? :Man <cword>

" Quick DOS/UNIX line endings
cmap dosfile e ++ff=dos %
cmap unixfile e ++ff=unix %

" Dragging lines
nnoremap <C-j> :m+<CR>
nnoremap <C-k> :m-2<CR>

" netrw - toggle file explorer
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
map <silent> <C-F> :call ToggleVExplorer()<CR>
let g:netrw_browse_split = 4
let g:netrw_altv = 1
let g:netrw_liststyle=3
set autochdir

syntax enable

" Tabbing for specific file types
augroup filetype_indent
  autocmd!
  autocmd FileType c,cpp,h,python setlocal expandtab
  autocmd FileType make setlocal noexpandtab
  autocmd FileType go setlocal noexpandtab tabstop=4 shiftwidth=4
augroup END

" Highlight trailing whitespace or leading tabs
highlight BadWhitespace ctermbg=darkred guibg=darkred
augroup bad_whitespace
  autocmd!
  autocmd BufRead,BufNewFile *.c,*.cpp,*.h,*.py,*.pyw match BadWhitespace /\(\s\+$\)\|\(^\t\+\)/
augroup END

" " Automatically indent based on file type:
" filetype indent on
" " Folding
" set foldmethod=indent       "Set folding based on indentation
" 
" "disable paste mode when leaving insert mode
" au InsertLeave * set nopaste
" 
" set autoindent              " Auto-indent new lines
" set autoread                " Reload files when changed on disk
" set backspace=indent,eol,start
" "set clipboard=unnamed       " Yank and paste with the system clipboard
" set encoding=utf-8          " Set the default file encoding to UTF-8
" set expandtab               " Use spaces instead of tabs
" set ignorecase              " Always case-insensitive
" set incsearch               " Searches for strings incrementally
" "set list   " Show trailing whitespace
" set linebreak               " Break lines at word
" set number                  " Show line numbers
" set ruler                   " Show row and column ruler information
" set shiftwidth=4            " Number of auto-indent spaces
" set showbreak=+++           " Wrap-broken line prefix
" set showmatch               " Highlight matching brace
" set smartcase               " Enable smart-case search
" set smartindent             " Enable smart-indent
" set softtabstop=4           " Number of spaces per Tab
" set timeoutlen=200          " Crimes against humanity absolved
" set undolevels=1024         " Number of undo levels
" 
" "========="
" " Hotkeys "
" "========="
" " easy unhighlight
" nnoremap nh :noh<cr>
" 
" " Tab management
" nnoremap <C-t>  :tabnew<CR>
" nnoremap te     :tabedit<Space>
" nnoremap tl     :tabnext<CR>
" nnoremap th     :tabprev<CR>
" nnoremap tL     :tablast<CR>
" nnoremap tm     :tabm<Space>
" nnoremap td     :tabclose<CR>
" 
" " C-s saves as sudo
" cnoremap <C-s>  :w !sudo tee %
" 
" " Reselect visual block after indent/dedent
" vnoremap < <gv
" vnoremap > >gv
" 
" " Move down wrapped lines intutively
" nnoremap j gj
" nnoremap k gk
" 
" " Remap man pages, overwriting the backward search
" nnoremap ? :Man <cword>
" 
" 
" " DOS/UNIX filetype switch for ^M line endings
" cmap dosfile ed ++ff=dos %
" cmap unixfile ed ++ff=unix %
" 
" " Dragging lines
" nnoremap <C-j> :m+<CR>
" nnoremap <C-k> :m-2<CR>
" 
" " F8 toggles paste mode
" " set pastetoggle=<F8>
" 
" " netrw config to emulate NERDtree
" " Toggle Vexplore with Ctrl-E
" function! ToggleVExplorer()
"   if exists("t:expl_buf_num")
"       let expl_win_num = bufwinnr(t:expl_buf_num)
"       if expl_win_num != -1
"           let cur_win_nr = winnr()
"           exec expl_win_num . 'wincmd w'
"           close
"           exec cur_win_nr . 'wincmd w'
"           unlet t:expl_buf_num
"       else
"           unlet t:expl_buf_num
"       endif
"   else
"       exec '1wincmd w'
"       Vexplore
"       let t:expl_buf_num = bufnr("%")
"   endif
" endfunction
" map <silent> <C-F> :call ToggleVExplorer()<CR>
" " Hit enter in the file browser to open the selected
" " file with :vsplit to the right of the browser.
" let g:netrw_browse_split = 4
" let g:netrw_altv = 1
" " Default to tree mode
" let g:netrw_liststyle=3
" " Change directory to the current buffer when opening files.
" set autochdir
" 
" syntax enable
" 
" " Use proper tabbing/spacing
" au BufRead,BufNewFile *.c,*.h,*.py,*.pyw set expandtab
" au BufRead,BufNewFile Makefile* set noexpandtab
" 
" " Use the below highlight group when displaying bad whitespace is desired.
" highlight BadWhitespace ctermbg=darkred guibg=darkred
" 
" " Display tabs at the beginning of a line in Python mode as bad.
" au BufRead,BufNewFile *.py,*.pyw,*.c,*.cpp,*.h match BadWhitespace /^\t\+/
" 
" " Make trailing whitespace be flagged as bad.
" au BufRead,BufNewFile *.py,*.pyw,*.c,*.cpp,*.h match BadWhitespace /\s\+$/
" 
" autocmd BufNewFile,BufRead *.go setlocal noexpandtab tabstop=4 shiftwidth=4
