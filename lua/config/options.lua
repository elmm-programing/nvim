local opt = vim.opt

-- Basic UI
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.laststatus = 3
opt.showmode = false
opt.pumheight = 10
opt.termguicolors = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.mouse = "a"
opt.wrap = false

-- Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true
opt.list = true
opt.listchars = { tab = "  ", trail = "·", nbsp = "␣" }
opt.fillchars = { eob = " " }

-- Search
opt.hlsearch = true
opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true

-- Files
opt.swapfile = false
opt.backup = false
opt.undodir = vim.fn.stdpath("data") .. "/undodir"
opt.undofile = true
opt.clipboard = "unnamedplus"

-- Window management
opt.splitright = true
opt.splitbelow = true

-- Timing
opt.updatetime = 250
opt.timeoutlen = 300
opt.ttimeoutlen = 0

-- Completion
opt.completeopt = "menu,menuone,noselect"
opt.shortmess:append("c")

-- Folding
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldenable = true

-- Sessions
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" }
opt.viewoptions = { "cursor", "folds", "slash", "unix" }

-- Disable unused legacy providers (silences checkhealth warnings)
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

-- Performance
opt.synmaxcol = 240
opt.redrawtime = 10000
opt.maxmempattern = 50000

-- Disable unused built-in plugins (keep matchit/matchparen)
vim.g.loaded_gzip = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_tohtml = 1
vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_zipPlugin = 1

-- Better diff options
opt.diffopt:append("linematch:60")

-- Better spell checking
opt.spelllang = { "en" }

-- Auto-write changes
opt.autowrite = true
