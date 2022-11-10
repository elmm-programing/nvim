-----------------------------------------------------------
-- Plugin manager configuration file
-----------------------------------------------------------

-- Plugin manager: packer.nvim
-- url: https://github.com/wbthomason/packer.nvim

-- For information about installed plugins see the README:
-- neovim-lua/README.md
-- https://github.com/brainfucksec/neovim-lua#readme


-- Automatically install packer
local fn = vim.fn
local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'

if fn.empty(fn.glob(install_path)) > 0 then
  packer_bootstrap = fn.system({
    'git',
    'clone',
    '--depth',
    '1',
    'https://github.com/wbthomason/packer.nvim',
    install_path
  })
  vim.o.runtimepath = vim.fn.stdpath('data') .. '/site/pack/*/start/*,' .. vim.o.runtimepath
end

-- Autocommand that reloads neovim whenever you save the packer_init.lua file
vim.cmd [[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost packer_init.lua source <afile> | PackerSync
  augroup end
]]

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, 'packer')
if not status_ok then
  return
end

-- Install plugins
return packer.startup(function(use)

use 'morhetz/gruvbox'
use {'sonph/onehalf',  rtp= 'vim' }
use 'fatih/vim-go'
use 'puremourning/vimspector'
use 'easymotion/vim-easymotion'
use {'akinsho/bufferline.nvim', tag = "v2.*", requires = 'kyazdani42/nvim-web-devicons'}
use 'scrooloose/nerdtree'
use 'vim-airline/vim-airline'
use 'honza/vim-snippets'
use 'ryanoasis/vim-devicons'
use 'vim-test/vim-test'
use 'mikelue/vim-maven-plugin'
use 'liuchengxu/vista.vim'
use 'tpope/vim-commentary'
use 'hdiniz/vim-gradle'
use 'junegunn/fzf'
use 'junegunn/fzf.vim'
use 'tpope/vim-surround'
use {'mg979/vim-visual-multi', branch= 'master'}
use 'vim-airline/vim-airline-themes'
use 'christoomey/vim-tmux-navigator'
use {'neoclide/coc.nvim', branch= 'release'}
use 'rafi/awesome-vim-colorschemes'
use 'frazrepo/vim-rainbow'
use {'styled-components/vim-styled-components',  branch='main' }
use 'christoomey/vim-system-copy'
use 'hrsh7th/vim-vsnip'
use 'rafamadriz/friendly-snippets'
use 'airblade/vim-rooter'
use 'jiangmiao/auto-pairs'
use 'tiagofumo/vim-nerdtree-syntax-highlight'
use {'akinsho/bufferline.nvim', tag = "v2.*", requires = 'kyazdani42/nvim-web-devicons'}
  -- Add you plugins here:
  use 'wbthomason/packer.nvim' -- packer can manage itself


  -- Autopair
  use {
    'windwp/nvim-autopairs',
    config = function()
      require('nvim-autopairs').setup{}
    end
  }

  -- Icons
  use 'kyazdani42/nvim-web-devicons'


  -- Color schemes
  use 'navarasu/onedark.nvim'
  use 'tanvirtin/monokai.nvim'
  use { 'rose-pine/neovim', as = 'rose-pine' }

  -- git labels
  use {
    'lewis6991/gitsigns.nvim',
    requires = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('gitsigns').setup{}
    end
  }

  -- Dashboard (start screen)
  use {
    'goolord/alpha-nvim',
    requires = { 'kyazdani42/nvim-web-devicons' },
  }

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)
