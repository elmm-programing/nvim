-- This file can be loaded by calling `lua require('plugins')` from your init.vim
-- Only required if you have packer configured as `opt`
vim.cmd.packadd('packer.nvim')

return require('packer').startup(function(use)
    --nulls formatter
    use "nvim-lua/plenary.nvim"

	    -- Packer can manage itself
	    use 'wbthomason/packer.nvim'

	    -- Fuzzy Finder (files, lsp, etc)
	    use { 'nvim-telescope/telescope.nvim', branch = '0.1.x', requires = { 'nvim-lua/plenary.nvim' } }

	    -- Fuzzy Finder Algorithm which requires local dependencies to be built. Only load if `make` is available
	    use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make', cond = vim.fn.executable 'make' == 1 }
	    use({
	        'rose-pine/neovim',
	        as = 'rose-pine',
	        config = function()
		        vim.cmd('colorscheme rose-pine')
	        end
	    })

	    use({ "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" })
	    use("nvim-treesitter/playground")
	    use("theprimeagen/harpoon")
	    use("theprimeagen/refactoring.nvim")
	    use("mbbill/undotree")
	    use("tpope/vim-fugitive")
	    use("nvim-treesitter/nvim-treesitter-context");
use( "jose-elias-alvarez/null-ls.nvim")
    use("jay-babu/mason-null-ls.nvim")
	    use {
	        'VonHeikemen/lsp-zero.nvim',
	        branch = 'v1.x',
	        requires = {
	            -- LSP Support
	            { 'neovim/nvim-lspconfig' },
	            { 'williamboman/mason.nvim' },
	            { 'williamboman/mason-lspconfig.nvim' },
	            -- Useful status updates for LSP
	            { 'j-hui/fidget.nvim' },

	            -- Additional lua configuration, makes nvim stuff amazing
	            { 'folke/neodev.nvim' },

	            -- Autocompletion
	            { 'hrsh7th/nvim-cmp' },
	            { 'hrsh7th/cmp-buffer' },
	            { 'hrsh7th/cmp-path' },
	            { 'saadparwaiz1/cmp_luasnip' },
	            { 'hrsh7th/cmp-nvim-lsp' },
	            { 'hrsh7th/cmp-nvim-lua' },
	            -- Snippets
	            { 'L3MON4D3/LuaSnip' },
	            { 'rafamadriz/friendly-snippets' },
	        }
	    }
	    use 'lukas-reineke/indent-blankline.nvim' -- Add indentation guides even on blank lines
	    use 'numToStr/Comment.nvim' -- "gc" to comment visual regions/lines
	    use 'tpope/vim-sleuth' -- Detect tabstop and shiftwidth automatically
	    use 'ryanoasis/vim-devicons'
	    use { 'tzachar/cmp-tabnine', run = './install.sh', requires = 'hrsh7th/nvim-cmp' }
	    use 'nvim-lualine/lualine.nvim'
	    use 'scrooloose/nerdtree'
	    use 'christoomey/vim-tmux-navigator'
	    use 'frazrepo/vim-rainbow'
	    use 'christoomey/vim-system-copy'
	    use 'jiangmiao/auto-pairs'
	    use "rafamadriz/friendly-snippets"

	    use("folke/zen-mode.nvim")
	    use("github/copilot.vim")
	    use("eandrju/cellular-automaton.nvim")
	    use("laytan/cloak.nvim")
    end)
