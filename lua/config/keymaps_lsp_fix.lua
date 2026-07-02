-- LSP keymaps with treesitter bug workaround
local M = {}

-- Neovim 0.12.3 has a treesitter bug with conceal_line provider
-- Monkey-patch open_floating_preview to disable treesitter during hover
local _original_open_floating_preview = vim.lsp.util.open_floating_preview
vim.lsp.util.open_floating_preview = function(contents, syntax, opts)
  -- Save and disable treesitter for all buffers
  local saved_states = {}
  pcall(function()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      local highlighter = vim.treesitter.highlighter.active[bufnr]
      if highlighter then
        saved_states[bufnr] = true
        pcall(vim.treesitter.stop, bufnr)
      end
    end
  end)
  
  -- Call original with error handling
  local ok, result = pcall(_original_open_floating_preview, contents, syntax, opts)
  
  -- Re-enable treesitter after delay
  vim.defer_fn(function()
    pcall(function()
      for bufnr, _ in pairs(saved_states) do
        if vim.api.nvim_buf_is_valid(bufnr) then
          local ft = vim.bo[bufnr].filetype
          if ft and ft ~= "" then
            local lang = vim.treesitter.language.get_lang(ft) or ft
            pcall(vim.treesitter.start, bufnr, lang)
          end
        end
      end
    end)
  end, 200)
  
  if not ok then
    error(result)
  end
  return result
end

map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
map("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
map("n", "gr", vim.lsp.buf.references, { desc = "Find references" })
map("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
map("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })

return M
