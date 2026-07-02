-- Fix for Neovim 0.12.3 treesitter crash during hover
-- The conceal_line provider crashes when nvim_win_text_height is called

-- Save original hover function
local _orig_hover = vim.lsp.buf.hover

-- Override hover to disable treesitter synchronously
vim.lsp.buf.hover = function(opts)
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype
  local lang = vim.treesitter.language.get_lang(ft) or ft
  
  -- Synchronously stop treesitter
  pcall(vim.treesitter.stop, bufnr)
  
  -- Call hover
  local ok, result = pcall(_orig_hover, opts)
  
  -- Re-enable treesitter synchronously
  pcall(vim.treesitter.start, bufnr, lang)
  
  if not ok then
    error(result)
  end
  return result
end

return { setup = function() end }
