--[[
sudo apt install lua5.3
Neovim init file
Maintainer: brainf+ck
Website: https://githukjkjb.com/brainfucksec/neovim-lua

--]]

-- Import Lua modules
require('packer_init')
require('core/options')
require('core/lualine')
--require('core/keymaps')
require('core/LSPSetting')
require('core/Telescope')
require('core/Treesitter')
require('core/cmp')
require('core/easyConfigs')

