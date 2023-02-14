--[[
sudo apt install lua5.3
Neovim init file
Maintainer: brainf+ck
Website: https://githukjkjb.com/brainfucksec/neovim-lua

--]]
-- Import Lua modules
require('packer_init')
require('core/remap')
require('core/plugins/lualine')
require('core/set')
require('core/plugins/cloak')
require('core/plugins/colors')
require('core/plugins/fugitive')
require('core/plugins/harpoon')
require('core/plugins/lsp')
require('core/plugins/refactoring')
require('core/plugins/telescope')
require('core/plugins/treesitter')
require('core/plugins/undotree')
require('core/plugins/zenmode')
require('core/plugins/easyConfigs')
-- require('core/LSPSetting')
-- require('core/Telescope')
-- require('core/Treesitter')
-- require('core/cmp')
-- require('core/easyConfigs')
-- require('core/luasnip')
--
