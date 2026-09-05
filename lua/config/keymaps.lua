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

-- Telescope
map("n", "<leader><leader>", "<cmd>Telescope find_files<CR>", { desc = "Find files", silent = true })
map("n", "<leader>/", "<cmd>Telescope live_grep<CR>", { desc = "Grep search", silent = true })

-- Undotree
map("n", "<leader>uu", "<cmd>UndotreeToggle<CR>", { desc = "Toggle undotree" })

-- Notifications / messages
map("n", "<leader>sn", function()
  require("snacks.notifier").show_history()
end, { desc = "Notifier history", silent = true })
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
