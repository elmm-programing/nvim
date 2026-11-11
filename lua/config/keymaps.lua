local map = vim.keymap.set

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { silent = true })

-- Window navigation (do not overwrite with LSP; signature help is gK / <C-s> in insert)
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Window resizing
map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height", silent = true })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height", silent = true })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width", silent = true })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width", silent = true })
map("n", "<leader>=", "<C-w>=", { desc = "Equalize window sizes" })

-- Buffer management
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer", silent = true })
map("n", "<leader>bD", "<cmd>bdelete!<CR>", { desc = "Force delete buffer", silent = true })
map("n", "<leader>bn", "<cmd>bnext<CR>", { desc = "Next buffer", silent = true })
map("n", "<leader>bp", "<cmd>bprevious<CR>", { desc = "Previous buffer", silent = true })
map("n", "]b", "<cmd>bnext<CR>", { desc = "Next buffer", silent = true })
map("n", "[b", "<cmd>bprevious<CR>", { desc = "Previous buffer", silent = true })

-- Move lines
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Quick save and quit
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file", silent = true })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit", silent = true })
map("n", "<leader>Q", "<cmd>qa!<CR>", { desc = "Force quit all", silent = true })
map("n", "<leader>W", "<cmd>wa<CR>", { desc = "Save all files", silent = true })

-- Center search results
map("n", "n", "nzzzv", { desc = "Next search result centered" })
map("n", "N", "Nzzzv", { desc = "Previous search result centered" })

-- Delete to void register (clipboard already uses unnamedplus)
map({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete to void register" })
map("x", "<leader>p", '"_dP', { desc = "Paste without overwriting register" })

-- Disable Q (ex mode)
map("n", "Q", "<nop>")

-- nvim-lspconfig 2.x dropped :LspInfo; keep the old names
vim.api.nvim_create_user_command("LspInfo", function()
  vim.cmd.checkhealth("vim.lsp")
end, { desc = "Show LSP client status" })
vim.api.nvim_create_user_command("LspLog", function()
  vim.cmd.edit(vim.lsp.log.get_filename())
end, { desc = "Open LSP log" })
vim.api.nvim_create_user_command("LspRestart", function()
  local buf = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = buf })
  if #clients == 0 then
    vim.notify("No LSP clients on this buffer", vim.log.levels.WARN)
    return
  end
  for _, client in ipairs(clients) do
    vim.notify("Restarting " .. client.name, vim.log.levels.INFO)
    vim.lsp.stop_client(client.id, true)
  end
  vim.defer_fn(function()
    vim.cmd.edit()
  end, 200)
end, { desc = "Restart LSP clients on this buffer" })

-- Quick escape from insert mode
map("i", "kj", "<Esc>", { desc = "Exit insert mode", silent = true })

-- Telescope. Call the Lua API so an older Ubuntu Neovim does not try to run
-- the :Telescope command before that command exists.
map("n", "<leader><leader>", function()
  require("telescope.builtin").find_files()
end, { desc = "Find files", silent = true })
map("n", "<leader>/", function()
  require("telescope.builtin").live_grep()
end, { desc = "Grep search", silent = true })

-- Undotree
map("n", "<leader>uu", "<cmd>UndotreeToggle<CR>", { desc = "Toggle undotree" })

-- Notifications / messages
local function split_lines(text)
  local lines = {}
  if type(text) ~= "string" or text == "" then
    return lines
  end
  for line in (text .. "\n"):gmatch("(.-)\n") do
    lines[#lines + 1] = line
  end
  return lines
end

local function append_section(lines, title, body)
  lines[#lines + 1] = "# " .. title
  if type(body) ~= "string" or body == "" then
    lines[#lines + 1] = "(none)"
  else
    vim.list_extend(lines, split_lines(body))
  end
  lines[#lines + 1] = ""
end

local function copy_notifications()
  local lines = {}
  local ok, notifier = pcall(require, "snacks.notifier")
  if ok and type(notifier.get_history) == "function" then
    local history_ok, history = pcall(function()
      return notifier.get_history()
    end)
    local chunks = {}
    if not history_ok or type(history) ~= "table" or #history == 0 then
      chunks[1] = "(none)"
    else
      for _, notif in ipairs(history) do
        local level = type(notif.level) == "string" and notif.level:upper() or tostring(notif.level)
        local title = type(notif.title) == "string" and notif.title ~= "" and (" " .. notif.title) or ""
        local msg = type(notif.msg) == "string" and notif.msg or vim.inspect(notif.msg)
        chunks[#chunks + 1] = string.format("[%s]%s", level, title)
        chunks[#chunks + 1] = msg
        chunks[#chunks + 1] = ""
      end
    end
    append_section(lines, "Notifications", table.concat(chunks, "\n"))
  else
    append_section(lines, "Notifications", "(snacks notifier is not loaded)")
  end

  local messages = ""
  local messages_ok, messages_result = pcall(vim.api.nvim_exec2, "messages", { output = true })
  if messages_ok and type(messages_result) == "table" then
    messages = messages_result.output or ""
  end
  append_section(lines, "Messages", messages)

  local log = vim.lsp.log.get_filename()
  if vim.fn.filereadable(log) == 1 then
    local all = vim.fn.readfile(log)
    local start = math.max(1, #all - 39)
    local tail = {}
    for i = start, #all do
      tail[#tail + 1] = all[i]
    end
    append_section(lines, "LSP log (last 40 lines) " .. log, table.concat(tail, "\n"))
  else
    append_section(lines, "LSP log", "(no lsp.log yet)")
  end

  if lines[#lines] == "" then
    lines[#lines] = nil
  end

  local text = table.concat(lines, "\n")
  vim.fn.setreg("+", text)
  vim.fn.setreg("*", text)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].modifiable = false

  vim.cmd.tabnew()
  local empty = vim.api.nvim_get_current_buf()
  vim.api.nvim_win_set_buf(0, buf)
  if empty ~= buf and vim.api.nvim_buf_is_valid(empty) and vim.api.nvim_buf_get_name(empty) == "" then
    pcall(vim.api.nvim_buf_delete, empty, { force = true })
  end
  vim.keymap.set("n", "q", "<cmd>tabclose<CR>", { buffer = buf, nowait = true, silent = true })
  vim.keymap.set("n", "y", function()
    vim.fn.setreg("+", text)
    vim.fn.setreg("*", text)
    vim.api.nvim_echo({ { "Copied notifications", "Normal" } }, false, {})
  end, { buffer = buf, nowait = true, silent = true, desc = "Copy notifications again" })
  vim.api.nvim_echo({
    { "Copied notifications. This tab has the same text. Press q to close it.", "Normal" },
  }, false, {})
end

map("n", "<leader>sn", function()
  require("snacks.notifier").show_history()
end, { desc = "Notifier history", silent = true })
map("n", "<leader>sy", copy_notifications, { desc = "Copy all notifications", silent = true })
vim.api.nvim_create_user_command("CopyNotifications", copy_notifications, { desc = "Copy all notifications" })

local function copy_location(absolute)
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then
    vim.notify("No file name", vim.log.levels.WARN)
    return
  end
  local path = absolute and vim.fn.fnamemodify(name, ":p") or vim.fn.fnamemodify(name, ":.")
  local text = path .. "#L" .. vim.api.nvim_win_get_cursor(0)[1]
  vim.fn.setreg("+", text)
  vim.notify(text, vim.log.levels.INFO)
end

map("n", "<leader>yf", function()
  copy_location(false)
end, { desc = "Copy path and line" })
map("n", "<leader>yp", function()
  copy_location(true)
end, { desc = "Copy absolute path and line" })

map("v", "<leader>cc", function()
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
  if path == "" then
    path = "[No Name]"
  end
  local short = {
    typescriptreact = "tsx",
    javascriptreact = "jsx",
    typescript = "ts",
    javascript = "js",
  }
  local lang = short[vim.bo.filetype] or vim.bo.filetype
  local block = string.format('```%s filename="%s" line="%d"\n%s\n```', lang, path, start_line, table.concat(lines, "\n"))
  vim.fn.setreg("+", block)
  vim.notify("Copied code block", vim.log.levels.INFO)
end, { desc = "Copy as Markdown code block" })

map("n", "<leader>jp", function()
  local loop = vim.uv or vim.loop
  local found = vim.fs.find("package.json", { upward = true, stop = loop.os_homedir(), type = "file" })
  local path = found[1]
  if not path then
    vim.notify("No package.json found", vim.log.levels.WARN)
    return
  end
  local buf = vim.fn.bufadd(path)
  vim.fn.bufload(buf)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    border = "rounded",
  })
  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.keymap.set("n", "q", function()
    local config = vim.api.nvim_win_get_config(0)
    if config.relative ~= "" then
      close()
    end
  end, { buffer = buf, nowait = true, desc = "Close package.json" })
  vim.keymap.set("n", "<Esc>", function()
    local config = vim.api.nvim_win_get_config(0)
    if config.relative ~= "" then
      close()
    end
  end, { buffer = buf, nowait = true, desc = "Close package.json" })
end, { desc = "Open package.json" })
map("n", "<leader>sm", function()
  local msgs = vim.api.nvim_exec2("messages", { output = true }).output
  if msgs == "" then
    msgs = "(no messages)"
  end
  vim.fn.setreg("+", msgs)
  vim.notify("Copied messages to clipboard", vim.log.levels.INFO)
end, { desc = "Copy :messages to clipboard", silent = true })

map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Show diagnostic" })
map("n", "<leader>cI", "<cmd>LspInfo<CR>", { desc = "LSP Info", silent = true })
map("n", "[d", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Previous diagnostic" })
map("n", "]d", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic" })
map("n", "<leader>xq", vim.diagnostic.setloclist, { desc = "Diagnostic loclist" })

-- Tabs
map("n", "<leader><tab>n", "<cmd>tabnew<CR>", { desc = "New tab", silent = true })
map("n", "<leader><tab>c", "<cmd>tabclose<CR>", { desc = "Close tab", silent = true })
map("n", "<leader><tab>o", "<cmd>tabonly<CR>", { desc = "Only current tab", silent = true })
map("n", "<leader><tab>m", "<cmd>tabmove<CR>", { desc = "Move tab", silent = true })

-- UI toggles
map("n", "<leader>uw", function()
  vim.wo.wrap = not vim.wo.wrap
  vim.notify("Wrap " .. (vim.wo.wrap and "enabled" or "disabled"))
end, { desc = "Toggle wrap" })
map("n", "<leader>us", function()
  vim.wo.spell = not vim.wo.spell
  vim.notify("Spell " .. (vim.wo.spell and "enabled" or "disabled"))
end, { desc = "Toggle spell" })
map("n", "<leader>ul", function()
  vim.wo.number = not vim.wo.number
  vim.wo.relativenumber = vim.wo.number
end, { desc = "Toggle line numbers" })

-- Quickfix / location list (Trouble owns [q / ]q and falls back to these)
map("n", "[Q", "<cmd>cfirst<CR>", { desc = "First quickfix item", silent = true })
map("n", "]Q", "<cmd>clast<CR>", { desc = "Last quickfix item", silent = true })
map("n", "[l", "<cmd>lprev<CR>", { desc = "Previous location list item", silent = true })
map("n", "]l", "<cmd>lnext<CR>", { desc = "Next location list item", silent = true })

-- Better search
map("n", "*", "*N", { desc = "Search word under cursor (stay)" })
map("n", "#", "#N", { desc = "Search word under cursor backwards (stay)" })

-- Stay in visual mode after indenting
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- Beginning/end of line in insert mode
map("i", "<C-a>", "<C-o>^", { desc = "Beginning of line" })
map("i", "<C-e>", "<C-o>$", { desc = "End of line" })

-- Terminal mode escape
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
map("t", "<C-[>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Language-specific maps (buffer-local)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact", "vue" },
  callback = function()
    map("n", "<leader>cM", function()
      vim.lsp.buf.code_action({
        context = { only = { "source.addMissingImports.ts" } },
        apply = true,
      })
    end, { buffer = true, desc = "Add missing imports" })
    map("n", "<leader>cu", function()
      vim.lsp.buf.code_action({
        context = { only = { "source.removeUnused.ts" } },
        apply = true,
      })
    end, { buffer = true, desc = "Remove unused imports" })
  end,
})

-- Go maps use <leader>G so they do not steal git maps under <leader>g
vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  callback = function()
    map("n", "<leader>Gr", "<cmd>GoRun<CR>", { buffer = true, desc = "Go run" })
    map("n", "<leader>Gf", "<cmd>GoFillStruct<CR>", { buffer = true, desc = "Go fill struct" })
    map("n", "<leader>Ga", "<cmd>GoAddTags<CR>", { buffer = true, desc = "Go add tags" })
    map("n", "<leader>GA", "<cmd>GoAddTags json<CR>", { buffer = true, desc = "Go add json tags" })
    map("n", "<leader>Gm", "<cmd>GoModTidy<CR>", { buffer = true, desc = "Go mod tidy" })
    map("n", "<leader>Gi", "<cmd>GoIfErr<CR>", { buffer = true, desc = "Go if err != nil" })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function()
    map("n", "<leader>ji", function()
      require("jdtls").organize_imports()
    end, { buffer = true, desc = "Java organize imports" })
    map("n", "<leader>jv", function()
      require("jdtls").extract_variable()
    end, { buffer = true, desc = "Java extract variable" })
    map("v", "<leader>jv", function()
      require("jdtls").extract_variable(true)
    end, { buffer = true, desc = "Java extract variable" })
    map("n", "<leader>jc", function()
      require("jdtls").extract_constant()
    end, { buffer = true, desc = "Java extract constant" })
    map("v", "<leader>jc", function()
      require("jdtls").extract_constant(true)
    end, { buffer = true, desc = "Java extract constant" })
    map("n", "<leader>jm", function()
      require("jdtls").extract_method()
    end, { buffer = true, desc = "Java extract method" })
    map("v", "<leader>jm", function()
      require("jdtls").extract_method(true)
    end, { buffer = true, desc = "Java extract method" })
    map("n", "<leader>jt", function()
      require("jdtls").test_class()
    end, { buffer = true, desc = "Java test class" })
    map("n", "<leader>jn", function()
      require("jdtls").test_nearest_method()
    end, { buffer = true, desc = "Java test nearest" })
    map("n", "<leader>je", function()
      require("jdtls").super_implementation()
    end, { buffer = true, desc = "Java super implementation" })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "rust",
  callback = function()
    map("n", "<leader>Rr", function()
      vim.cmd.RustLsp("runnables")
    end, { buffer = true, desc = "Rust runnables" })
    map("n", "<leader>Rd", function()
      vim.cmd.RustLsp("debuggables")
    end, { buffer = true, desc = "Rust debuggables" })
    map("n", "<leader>Re", function()
      vim.cmd.RustLsp("expandMacro")
    end, { buffer = true, desc = "Rust expand macro" })
    map("n", "<leader>Rc", function()
      vim.cmd.RustLsp("flyCheck")
    end, { buffer = true, desc = "Rust fly check" })
  end,
})
