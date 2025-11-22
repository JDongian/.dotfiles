" Colors
colorscheme vim

" ---------- Core options (non-defaults only) ----------
set number
set linebreak
set foldmethod=indent

set expandtab
set shiftwidth=4
set softtabstop=4
set smartindent

set ignorecase
set smartcase
set showbreak=+++
set timeoutlen=200
set autochdir

" Disable paste mode when leaving insert
augroup paste_mode
  autocmd!
  autocmd InsertLeave * set nopaste
augroup END

" ---------- Tabs / windows ----------
nnoremap nh :noh<CR>
nnoremap <C-t>  :tabnew<CR>

" Reselect visual block after indent/dedent
vnoremap < <gv
vnoremap > >gv

" Open man page for word under cursor
nnoremap ? :Man <cword><CR>

" Quick DOS/UNIX line endings
cmap dosfile  e ++ff=dos  %
cmap unixfile e ++ff=unix %

" Dragging lines
nnoremap <C-j> :m+<CR>
nnoremap <C-k> :m-2<CR>

" ---------- File explorer (built-in netrw, short toggle) ----------
nnoremap <silent> <C-F> :Lexplore<CR>

" ---------- Filetype-specific indentation ----------
" 4-space soft tabs by default; real tabs for selected languages
augroup tabs_by_filetype
  autocmd!
  autocmd FileType make,go setlocal noexpandtab
augroup END

" ---------- Bad whitespace (all normal buffers) ----------
highlight BadWhitespace ctermbg=darkred guibg=darkred

augroup bad_whitespace
  autocmd!
  autocmd BufWinEnter *
        \ if &buftype == '' && &modifiable |
        \   match BadWhitespace /\s\+$\|^\t\+/ |
        \ endif
augroup END
