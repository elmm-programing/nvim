local g = vim.g       -- Global variables
local opt = vim.opt   -- Set options (global/buffer/windows-scoped)

vim.cmd [[
set runtimepath+=/usr/share/vim/vimfiles
set number
set completeopt=menu,menuone,noselect
set clipboard=unnamedplus
set mouse=a
set numberwidth=1
set nocompatible
syntax enable
set showcmd
set ruler
set cursorline
set encoding=utf-8
set showmatch
set sw=2
set wrap
set incsearch
set relativenumber
set laststatus=2
au BufNewFile,BufRead *.ejs set filetype=html
au BufNewFile,BufRead *.hbs set filetype=html
au BufNewFile,BufRead *.jsp set filetype=html
set noshowmode
" auto-format
autocmd BufWritePre *.js lua vim.lsp.buf.formatting_sync(nil, 100)
autocmd BufWritePre *.jsx lua vim.lsp.buf.formatting_sync(nil, 100)
if exists('+termguicolors')
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif
" Change these if you want
let g:signify_sign_add               = '+'
let g:signify_sign_delete            = '_'
let g:signify_sign_delete_first_line = '‾'
let g:signify_sign_change            = '~'
let g:completion_trigger_character = [',']
" I find the numbers disctracting
let g:signify_sign_show_count = 0
let g:signify_sign_show_text = 1


let g:prettier#autoformat = 0
let g:prettier#quickfix_enabled = 0
let g:prettier#quickfix_auto_focus = 0
let g:bracey_server_port=6060
let g:system_copy#copy_command='xclip -sel clipboard'
let g:system_copy#paste_command='xclip -sel clipboard -o'
:colorscheme gruvbox
let g:airline_theme='onedark'
let g:gruvbox_contrast_dark = "hard"
let NERDTreeQuitOnOpen=1
set pyxversion=3
let g:airline_powerline_fonts = 1
let g:go_def_mapping_enabled = 0
let g:vimspector_base_dir='/home/edwin/.config/nvim/general/plugged/vimspector'
let g:loaded_perl_provider = 0

]]


vim.opt.termguicolors = true
require("bufferline").setup{}
