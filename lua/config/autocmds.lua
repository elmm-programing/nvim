local augroup = vim.api.nvim_create_augroup("ConfigAutocmds", { clear = true })

-- Yank highlight is handled by yanky.nvim

vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  callback = function(args)
    if not vim.bo[args.buf].modifiable or vim.b[args.buf].large_file or vim.bo[args.buf].filetype == "bigfile" then
      return
    end
    local ft = vim.bo[args.buf].filetype
    if ft == "markdown" or ft == "gitcommit" then
      return
    end
    local view = vim.fn.winsaveview()
    vim.cmd([[silent! %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
  desc = "Trim trailing whitespace on save",
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
    vim.b.sleuth_automatic = 0
  end,
  desc = "Go uses tabs with width 4",
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = "java",
  callback = function()
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
    vim.b.sleuth_automatic = 0
  end,
  desc = "Java uses 4-space indent",
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "vue", "javascript", "typescript", "typescriptreact", "javascriptreact" },
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
    vim.b.sleuth_automatic = 0
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

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
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

-- Neovim HEAD crashes Treesitter conceal_line in markdown injection floats (K hover).
-- Hover docs are unnamed markdown buffers; stop TS before the first redraw.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "markdown", "lsp_markdown" },
  callback = function(ev)
    local buf = ev.buf
    if vim.api.nvim_buf_get_name(buf) ~= "" then
      return
    end
    local function stop_ts()
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      pcall(vim.treesitter.stop, buf)
      for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        pcall(vim.api.nvim_set_option_value, "conceallevel", 0, { win = win })
        pcall(vim.api.nvim_set_option_value, "concealcursor", "", { win = win })
      end
    end
    stop_ts()
    vim.schedule(stop_ts)
  end,
  desc = "Disable Treesitter in LSP hover markdown floats",
})

local function wipe_orphan_unnamed(keep)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= keep
      and vim.api.nvim_buf_is_valid(buf)
      and vim.bo[buf].buflisted
      and vim.api.nvim_buf_get_name(buf) == ""
      and vim.bo[buf].buftype == ""
      and not vim.bo[buf].modified
    then
      local ok, lines = pcall(vim.api.nvim_buf_get_lines, buf, 0, 2, false)
      if ok and (#lines == 0 or (#lines == 1 and (lines[1] == "" or lines[1] == nil))) then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
  end
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  group = augroup,
  callback = function(args)
    if vim.api.nvim_buf_get_name(args.buf) == "" then
      return
    end
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(args.buf) then
        wipe_orphan_unnamed(args.buf)
      end
    end)
  end,
  desc = "Wipe leftover [No Name] buffers after opening a file",
})

