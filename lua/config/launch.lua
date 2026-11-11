local M = {}

function M.bundled_nvim()
  local names = { vim.fn.expand("~/.local/nvim-tools/nvim/bin/nvim") }
  local localapp = vim.env.LOCALAPPDATA
  if type(localapp) == "string" and localapp ~= "" then
    names[#names + 1] = localapp .. "/nvim-tools/nvim/bin/nvim.exe"
    names[#names + 1] = localapp .. "\\nvim-tools\\nvim\\bin\\nvim.exe"
  end
  for _, bin in ipairs(names) do
    if vim.fn.executable(bin) == 1 then
      return bin
    end
  end
  return nil
end

function M.should_replace()
  if vim.fn.has("unix") ~= 1 or vim.fn.has("nvim-0.11") == 1 then
    return false
  end
  if vim.env.NVIM_SKIP_RELAUNCH == "1" then
    return false
  end
  for _, arg in ipairs(vim.v.argv or {}) do
    if arg == "--headless" or arg == "--embed" or arg == "-es" or arg == "-Es" or arg == "--api-info" then
      return false
    end
  end
  local bin = M.bundled_nvim()
  if not bin then
    return false
  end
  if vim.fn.resolve(bin) == vim.fn.resolve(vim.v.progpath) then
    return false
  end
  return true
end

local function exec_replace(bin)
  local ok, ffi = pcall(require, "ffi")
  if not ok then
    return
  end
  pcall(ffi.cdef, "int execv(const char *path, char *const argv[]);")

  local args = { bin }
  local argv = vim.v.argv or {}
  for i = 2, #argv do
    args[#args + 1] = argv[i]
  end

  local c_args = ffi.new("const char*[?]", #args + 1)
  local keep = {}
  for i, arg in ipairs(args) do
    keep[i] = ffi.new("char[?]", #arg + 1)
    ffi.copy(keep[i], arg)
    c_args[i - 1] = keep[i]
  end
  c_args[#args] = nil
  ffi.C.execv(bin, c_args)
end

function M.replace()
  if not M.should_replace() then
    return
  end
  exec_replace(M.bundled_nvim())
end

return M
