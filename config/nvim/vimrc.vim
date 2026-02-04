" Vim Config
filetype plugin indent on
syntax enable

" General
set encoding=utf-8
set ruler
set autowrite
set number relativenumber
set history=1000
set ttimeout ttimeoutlen=1 timeoutlen=200
set visualbell
set fileformats+=mac
set display+=lastline
set nofoldenable
set splitright splitbelow
set cursorline
set cursorcolumn
set pumheight=10
"set nowrap
set inccommand=nosplit
set showcmd
set termguicolors

" Indendation
set autoindent smarttab expandtab
set shiftround tabstop=2 shiftwidth=2

" Search
set gdefault
set ignorecase smartcase

set list
set listchars=tab:▸\ ,trail:•,extends:»,precedes:«,nbsp:¬
set scrolloff=1 sidescrolloff=5

" Status Line
set statusline=

set statusline +=%3*%y%*                "file type
set statusline +=%4*\ %<%F%*            "full path
set statusline +=%2*%m%*                "modified flag
set statusline +=%1*%=%5l%*             "current line
set statusline +=%2*/%L%*               "total lines
set statusline +=%1*%4v\ %*             "virtual column number
set statusline +=%2*0x%04B\ %*          "character under cursor

" Show the status on the second to last line
set laststatus=2

" Maps
map <F2> :echo "\t\t\t\t" . strftime('%a -- %d/%m/%G -- %T')<CR>
map <F3> :echo hostname()<CR>
nnoremap go o<Esc>
nnoremap gO O<Esc>
 
