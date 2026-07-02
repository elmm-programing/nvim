local augroup = vim.api.nvim_create_augroup("ConfigAutocmds", { clear = true })

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
  desc = "Highlight on yank",
})

-- Trim trailing whitespace on save
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  callback = function(args)
    if not vim.bo[args.buf].modifiable then return end
    local view = vim.fn.winsaveview()
    vim.cmd([[silent! %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
  desc = "Trim trailing whitespace on save",
})

-- Organize Go imports on save
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  group = augroup,
  pattern = "*.go",
  callback = function()
    vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
  end,
  desc = "Organize Go imports on save",
})

-- Filetype-specific indentation
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "json", "jsonc", "yaml", "yml", "toml", "markdown" },
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
  end,
  desc = "Set 2-space indent for data formats",
})

-- Go uses tabs with width 4
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = "go",
  callback = function()
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
    vim.bo.expandtab = false
  end,
  desc = "Go uses tabs with width 4",
})

-- Java uses 4-space indent
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = "java",
  callback = function()
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
  end,
  desc = "Java uses 4-space indent",
})

-- Vue/TS/JS uses 2-space indent
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "vue", "javascript", "typescript", "typescriptreact", "javascriptreact" },
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
  end,
  desc = "Vue/TS/JS uses 2-space indent",
})

-- Nuxt file type detection
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = augroup,
  pattern = { "*.nuxt", "*.page", "*.layout", "*.server" },
  callback = function()
    vim.bo.filetype = "vue"
  end,
  desc = "Treat Nuxt files as Vue",
})

-- Auto-create parent directories when saving
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  callback = function(args)
    local dir = vim.fn.fnamemodify(args.file, ':p:h')
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, 'p')
    end
  end,
  desc = "Create parent directories when saving",
})

-- Auto-reload files changed outside Neovim
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = augroup,
  callback = function()
    if vim.o.buftype == "" then
      vim.cmd("checktime")
    end
  end,
  desc = "Auto-reload changed files",
})

-- Jump to last position when reopening a file
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  callback = function(args)
    local exclude = { "gitcommit", "gitrebase" }
    if vim.tbl_contains(exclude, vim.bo[args.buf].filetype) then return end
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
  desc = "Jump to last position",
})

-- Treesitter crash workaround for Telescope and other floating windows
pcall(function()
  local ts = vim.treesitter
  local orig_get_node_text = ts.get_node_text
  ts.get_node_text = function(node, bufnr, opts)
    if not node then return nil end
    local ok, text = pcall(orig_get_node_text, node, bufnr, opts)
    if ok then return text end
    return nil
  end
  
  local orig_get_node_range = function(node)
    if not node then return {0, 0, 0, 0} end
    local ok, range = pcall(function() 
      local start_row, start_col, end_row, end_col = node:range()
      return {start_row, start_col, end_row, end_col}
    end)
    if ok then return range end
    return {0, 0, 0, 0}
  end
end)

-- Wrap LSP hover to disable treesitter before showing and re-enable after
vim.api.nvim_create_autocmd("LspAttach", {
  group = augroup,
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    
    if client and client.supports_method("textDocument/hover") then
      -- Override the hover function to disable treesitter during hover
      local orig_hover = vim.lsp.buf.hover
      vim.lsp.buf.hover = function()
        -- Disable treesitter in current buffer temporarily
        vim.treesitter.stop(bufnr)
        
        -- Call original hover
        orig_hover()
        
        -- Re-enable treesitter after a short delay
        vim.defer_fn(function()
          if vim.api.nvim_buf_is_valid(bufnr) then
            local ft = vim.bo[bufnr].filetype
            local lang = vim.treesitter.language.get_lang(ft)
            if lang then
              vim.treesitter.start(bufnr, lang)
            end
          end
        end, 100)
      end
    end
  end,
  desc = "Wrap LSP hover to prevent treesitter crashes",
})

-- Disable treesitter for Telescope preview buffers to avoid crashes
vim.api.nvim_create_autocmd("User", {
  group = augroup,
  pattern = "TelescopePreviewerLoaded",
  callback = function(args)
    vim.bo[args.buf].syntax = "off"
    vim.bo[args.buf].filetype = ""
  end,
  desc = "Disable treesitter for telescope previews",
})

-- Disable treesitter in hover windows (LSP floating preview) to avoid crashes
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "markdown", "nofile" },
  callback = function(args)
    -- Check if this is a floating window (hover)
    local winid = vim.api.nvim_get_current_win()
    local win_config = vim.api.nvim_win_get_config(winid)
    if win_config.relative and win_config.relative ~= "" then
      -- This is a floating window, disable treesitter
      vim.treesitter.stop(args.buf)
    end
  end,
  desc = "Disable treesitter in hover windows",
})

-- Disable treesitter injections in Go files (common crash source)
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = "go",
  callback = function(args)
    -- Disable problematic injections
    vim.b[args.buf].treesitter_disable_injections = true
    -- Also disable conceal which interacts badly with treesitter
    vim.opt_local.conceallevel = 0
  end,
  desc = "Disable treesitter injections in Go files",
})

-- Automatically close quickfix when selecting item
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = "qf",
  callback = function()
    vim.keymap.set("n", "<CR>", "<CR>:cclose<CR>", { buffer = true, silent = true })
  end,
  desc = "Auto-close quickfix on selection",
})

-- Terminal mode auto-insert
vim.api.nvim_create_autocmd("TermOpen", {
  group = augroup,
  callback = function()
    vim.cmd("startinsert")
  end,
  desc = "Auto-insert in terminal",
})

-- Highlight matching parentheses
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
  group = augroup,
  callback = function()
    vim.cmd("silent! doautocmd matchparen CursorMoved")
  end,
  desc = "Highlight matching parentheses",
})

-- Set up Nuxt-specific settings when in a Nuxt project
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  group = augroup,
  callback = function()
    local cwd = vim.fn.getcwd()
    local nuxt_config = cwd .. "/nuxt.config.ts"
    local nuxt_config_js = cwd .. "/nuxt.config.js"
    
    if vim.fn.filereadable(nuxt_config) == 1 or vim.fn.filereadable(nuxt_config_js) == 1 then
      -- Enable Nuxt-specific settings
      vim.g.nuxt_project = true
      
      -- Set up path aliases for Nuxt
      vim.g.nuxt_path_aliases = {
        ["~"] = cwd,
        ["@"] = cwd,
        ["~~"] = cwd,
        ["@@"] = cwd,
      }
      
      -- Auto-detect Vue files in Nuxt projects
      if vim.bo.filetype == "vue" then
        -- Enable Nuxt-specific completions
        vim.b.nuxt_mode = true
      end
    end
  end,
  desc = "Detect Nuxt project settings",
})

-- Performance: disable syntax highlighting for large files
vim.api.nvim_create_autocmd("BufReadPre", {
  group = augroup,
  callback = function(args)
    local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(args.buf))
    if ok and stats and stats.size > 1024 * 1024 then -- 1MB
      vim.opt_local.syntax = "off"
      vim.opt_local.filetype = ""
      vim.notify("Large file detected - syntax highlighting disabled", vim.log.levels.WARN)
    end
  end,
  desc = "Disable syntax for large files",
})

-- Global fix: Disable treesitter highlight in all floating windows to prevent crashes
vim.api.nvim_create_autocmd("WinNew", {
  group = augroup,
  callback = function()
    vim.schedule(function()
      local winid = vim.api.nvim_get_current_win()
      local win_config = vim.api.nvim_win_get_config(winid)
      if win_config.relative and win_config.relative ~= "" then
        -- Floating window detected - disable treesitter
        local bufnr = vim.api.nvim_win_get_buf(winid)
        if vim.api.nvim_buf_is_valid(bufnr) then
          vim.treesitter.stop(bufnr)
        end
      end
    end)
  end,
  desc = "Disable treesitter in floating windows",
})

-- Disable conceal_line decoration provider globally (Neovim 0.12.3 bug workaround)
local conceal_line_group = vim.api.nvim_create_augroup("DisableConcealLine", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "WinEnter" }, {
  group = conceal_line_group,
  callback = function(args)
    local bufnr = args.buf
    local ft = vim.bo[bufnr].filetype
    -- Only apply to filetypes that use treesitter
    if ft and ft ~= "" and ft ~= "lazy" and ft ~= "mason" and ft ~= "TelescopePrompt" then
      pcall(function()
        -- Disable conceal_line provider by removing it from highlighter
        local highlighter = vim.treesitter.highlighter.active[bufnr]
        if highlighter then
          for _, tree in ipairs(highlighter._trees) do
            tree:parse(true) -- Force reparse
          end
        end
      end)
    end
  end,
  desc = "Workaround for conceal_line treesitter bug",
})

-- More aggressive fix: Disable conceal_line provider entirely for Neovim 0.12.3
-- This provider crashes when processing treesitter injections in floating windows
vim.api.nvim_create_autocmd("VimEnter", {
  group = augroup,
  callback = function()
    -- Disable conceal_line globally by clearing the decoration provider
    pcall(function()
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        local highlighter = vim.treesitter.highlighter.active[bufnr]
        if highlighter then
          -- Clear all decoration providers
          highlighter._decoration_providers = {}
          -- Force reparse to reset state
          for _, tree in ipairs(highlighter._trees or {}) do
            tree:parse(true)
          end
        end
      end
    end)
  end,
  desc = "Disable conceal_line provider globally",
})
