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
opt.listchars = { tab = "▸ ", trail = "·", nbsp = "␣" }
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
-- clipboard can block on WSL/SSH/macOS; attach after UI is up.
-- Citrix and SSH sessions often have no clipboard tool. OSC 52 lets yank
-- reach the local terminal when that is the case, or when NVIM_FORCE_OSC52=1.
vim.schedule(function()
  local function has_clipboard_tool()
    if vim.fn.has("win32") == 1 or vim.fn.has("wsl") == 1 then
      return true
    end
    for _, exe in ipairs({ "pbcopy", "wl-copy", "xclip", "xsel", "win32yank" }) do
      if vim.fn.executable(exe) == 1 then
        return true
      end
    end
    return false
  end

  local remote = vim.env.SSH_TTY or vim.env.SSH_CONNECTION or vim.env.CITRIX or vim.env.CITRIX_VERSION
  local force = vim.env.NVIM_FORCE_OSC52 == "1"
  if force or (remote and not has_clipboard_tool()) then
    local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
    if ok then
      vim.g.clipboard = {
        name = "osc52",
        copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
        paste = { ["+"] = osc52.paste("+"), ["*"] = osc52.paste("*") },
      }
    else
      local copied = { "" }
      local function encode(text)
        if vim.base64 and vim.base64.encode then
          return vim.base64.encode(text)
        end
        return vim.fn.system({ "base64" }, text):gsub("%s+", "")
      end
      local function copy(lines)
        copied = lines
        local payload = "\027]52;c;" .. encode(table.concat(lines, "\n")) .. "\027\\"
        if vim.api.nvim_ui_send then
          pcall(vim.api.nvim_ui_send, payload)
        else
          io.stdout:write(payload)
          io.stdout:flush()
        end
      end
      vim.g.clipboard = {
        name = "osc52",
        copy = { ["+"] = copy, ["*"] = copy },
        paste = { ["+"] = function() return copied end, ["*"] = function() return copied end },
      }
    end
  end
  vim.opt.clipboard = "unnamedplus"
end)

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

-- go.nvim health: GOBIN + PATH so GOPATH/bin tools are visible
local gobin = vim.fn.expand("~/go/bin")
if vim.fn.isdirectory(gobin) == 1 then
  vim.env.GOBIN = gobin
  if vim.env.PATH and not vim.env.PATH:find(gobin, 1, true) then
    vim.env.PATH = gobin .. ":" .. vim.env.PATH
  end
end

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
