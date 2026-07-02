-- Treesitter workaround for Neovim 0.12.3 bug
-- The conceal_line provider crashes when processing injections in floating windows

local M = {}

-- Disable treesitter injections globally
function M.disable_injections()
  pcall(function()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      local highlighter = vim.treesitter.highlighter.active[bufnr]
      if highlighter then
        -- Clear injection queries
        for _, tree in ipairs(highlighter._trees or {}) do
          tree:parse(true)
        end
      end
    end
  end)
end

-- Override vim.lsp.util.open_floating_preview to disable treesitter
local _original_open_floating_preview = vim.lsp.util.open_floating_preview
vim.lsp.util.open_floating_preview = function(contents, syntax, opts)
  -- Disable all treesitter highlighting before opening floating window
  pcall(function()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.treesitter.highlighter.active[bufnr] then
        vim.treesitter.stop(bufnr)
      end
    end
  end)
  
  -- Call original
  local ok, result = pcall(_original_open_floating_preview, contents, syntax, opts)
  
  -- Re-enable after delay
  vim.defer_fn(function()
    pcall(function()
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype ~= "" then
          local ft = vim.bo[bufnr].filetype
          local lang = vim.treesitter.language.get_lang(ft) or ft
          pcall(vim.treesitter.start, bufnr, lang)
        end
      end
    end)
  end, 300)
  
  if not ok then
    error(result)
  end
  return result
end

return M
