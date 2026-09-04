local augroup = vim.api.nvim_create_augroup("ConfigAutocmds", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
  desc = "Highlight on yank",
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  callback = function(args)
    if not vim.bo[args.buf].modifiable then
      return
    end
    local view = vim.fn.winsaveview()
    vim.cmd([[silent! %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
  desc = "Trim trailing whitespace on save",
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  pattern = "*.go",
  callback = function()
    pcall(vim.lsp.buf.code_action, {
      apply = true,
      context = { only = { "source.organizeImports" } },
    })
  end,
  desc = "Organize Go imports on save",
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "json", "jsonc", "yaml", "yml", "toml", "markdown" },
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
  end,
  desc = "Set 2-space indent for data formats",
})

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

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = "java",
  callback = function()
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
  end,
  desc = "Java uses 4-space indent",
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "vue", "javascript", "typescript", "typescriptreact", "javascriptreact" },
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
  end,
  desc = "Vue/TS/JS uses 2-space indent",
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  callback = function(args)
    local dir = vim.fn.fnamemodify(args.file, ":p:h")
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
  end,
  desc = "Create parent directories when saving",
})

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  group = augroup,
  callback = function()
    if vim.o.buftype == "" then
      vim.cmd("checktime")
    end
  end,
  desc = "Auto-reload changed files",
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  callback = function(args)
    local exclude = { "gitcommit", "gitrebase" }
    if vim.tbl_contains(exclude, vim.bo[args.buf].filetype) then
      return
    end
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
  desc = "Jump to last position",
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = "qf",
  callback = function()
    vim.keymap.set("n", "<CR>", "<CR>:cclose<CR>", { buffer = true, silent = true })
  end,
  desc = "Auto-close quickfix on selection",
})

vim.api.nvim_create_autocmd("TermOpen", {
  group = augroup,
  callback = function()
    vim.cmd("startinsert")
  end,
  desc = "Auto-insert in terminal",
})

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  group = augroup,
  callback = function()
    local cwd = vim.fn.getcwd()
    if vim.fn.filereadable(cwd .. "/nuxt.config.ts") == 1 or vim.fn.filereadable(cwd .. "/nuxt.config.js") == 1 then
      vim.g.nuxt_project = true
      vim.g.nuxt_path_aliases = {
        ["~"] = cwd,
        ["@"] = cwd,
        ["~~"] = cwd,
        ["@@"] = cwd,
      }
    end
  end,
  desc = "Detect Nuxt project settings",
})

vim.api.nvim_create_autocmd("BufReadPre", {
  group = augroup,
  callback = function(args)
    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(args.buf))
    if ok and stats and stats.size > 1024 * 1024 then
      vim.bo[args.buf].syntax = "off"
      vim.notify("Large file detected — syntax highlighting disabled", vim.log.levels.WARN)
    end
  end,
  desc = "Disable syntax for large files",
})
