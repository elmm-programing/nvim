vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Ubuntu's packaged Neovim is older than 0.11. Switch to the installer copy
-- before plugins load, so lspconfig does not warn and vue_ls exists.
require("config.launch").replace()

require("config.options")
require("config.keymaps")
require("config.lazy")
require("config.autocmds")
