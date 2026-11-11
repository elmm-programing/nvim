local M = {}

-- jdtls 1.63 bundles such as org.eclipse.core.filesystem are Java 25 class
-- files (major 69). JDK 21 can load the equinox launcher and then fail while
-- resolving those bundles. Older JDKs stay available as project runtimes.
local LAUNCHER_MIN = 25
local PROJECT_MIN = 17

local function trim_slash(path)
  if type(path) ~= "string" then
    return nil
  end
  path = path:gsub("[/\\]+$", "")
  if path == "" then
    return nil
  end
  return path
end

function M.executable(home)
  home = trim_slash(home)
  if not home then
    return nil
  end
  local names = { home .. "/bin/java", home .. "/bin/java.exe" }
  for _, bin in ipairs(names) do
    if vim.fn.executable(bin) == 1 then
      return bin
    end
  end
  return nil
end

local function is_jdk(home)
  local names = { home .. "/bin/javac", home .. "/bin/javac.exe" }
  for _, bin in ipairs(names) do
    if vim.fn.executable(bin) == 1 then
      return true
    end
  end
  return false
end

function M.major(bin)
  if type(bin) ~= "string" or bin == "" or vim.fn.executable(bin) ~= 1 then
    return nil
  end
  local out = vim.fn.system({ bin, "-version" })
  local quoted = out:match('version "([^"]+)"') or ""
  local modern = quoted:match("^(%d+)")
  local legacy = quoted:match("^1%.(%d+)")
  return tonumber(legacy or modern)
end

local function add_home(list, seen, home)
  if type(home) ~= "string" or vim.trim(home) == "" then
    return
  end
  home = trim_slash(vim.fn.fnamemodify(vim.fn.expand(home), ":p"))
  if not home or seen[home] then
    return
  end
  seen[home] = true
  list[#list + 1] = home
end

local function home_from_bin(bin)
  if type(bin) ~= "string" or bin == "" then
    return nil
  end
  bin = vim.trim(bin)
  if vim.fn.executable(bin) ~= 1 and vim.fn.filereadable(bin) ~= 1 then
    return nil
  end
  local resolved = vim.fn.resolve(bin)
  if resolved == "" then
    resolved = bin
  end
  return trim_slash(vim.fn.fnamemodify(resolved, ":p:h:h"))
end

local function consider_dir(list, seen, dir)
  dir = trim_slash(dir and vim.fn.expand(dir) or nil)
  if not dir or vim.fn.isdirectory(dir) ~= 1 then
    return
  end
  if M.executable(dir) then
    add_home(list, seen, dir)
    return
  end
  local children = vim.fn.glob(dir .. "/*", true, true)
  for _, child in ipairs(children) do
    if M.executable(child) then
      add_home(list, seen, child)
    end
  end
end

local function read_java_home_file()
  local path = vim.fn.expand("~/.local/nvim-tools/java-home")
  if vim.fn.filereadable(path) ~= 1 then
    local localapp = vim.env.LOCALAPPDATA
    if type(localapp) == "string" and localapp ~= "" then
      path = localapp .. "/nvim-tools/java-home"
    end
  end
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end
  local line = vim.fn.readfile(path)[1]
  if type(line) ~= "string" then
    return nil
  end
  line = vim.trim(line)
  line = line:gsub("%${NVIM_TOOLS}", vim.fn.expand("~/.local/nvim-tools"))
  line = line:gsub("%${HOME}", vim.fn.expand("~"))
  line = line:gsub("^~", vim.fn.expand("~"))
  return line
end

local function home_from_login_shell()
  if vim.env.NVIM_JAVA_SKIP_SHELL == "1" or vim.fn.executable("bash") ~= 1 then
    return nil
  end
  local out = vim.fn.system({ "bash", "-lc", "command -v java" })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  local bin
  for line in out:gmatch("[^\r\n]+") do
    if line:sub(1, 1) == "/" then
      bin = line
    end
  end
  return home_from_bin(bin)
end

local function collect(opts)
  opts = opts or {}
  local homes = {}
  local seen = {}

  local function add_bin(bin)
    add_home(homes, seen, home_from_bin(bin))
  end

  for _, home in ipairs(opts.homes or {}) do
    add_home(homes, seen, home)
  end
  for _, bin in ipairs(opts.bins or {}) do
    add_bin(bin)
  end

  if opts.isolated then
    local roots = {}
    for _, root in ipairs(opts.roots or {}) do
      roots[#roots + 1] = root
    end
    for _, root in ipairs(roots) do
      consider_dir(homes, seen, root)
      local nested = vim.fn.glob(vim.fn.expand(root) .. "/*", true, true)
      for _, child in ipairs(nested) do
        consider_dir(homes, seen, child)
      end
    end
    return homes
  end

  add_home(homes, seen, vim.env.JAVA_HOME)
  add_home(homes, seen, read_java_home_file())
  add_home(homes, seen, "~/.local/nvim-tools/jdk")
  if type(vim.env.LOCALAPPDATA) == "string" and vim.env.LOCALAPPDATA ~= "" then
    add_home(homes, seen, vim.env.LOCALAPPDATA .. "/nvim-tools/jdk")
  end
  add_home(homes, seen, "~/.sdkman/candidates/java/current")

  add_bin(vim.fn.exepath("java"))
  add_bin("/usr/bin/java")
  add_bin("/usr/local/bin/java")
  add_bin("/etc/alternatives/java")
  add_bin("/etc/alternatives/javac")

  local roots = {
    "/usr/lib/jvm",
    "/usr/lib64/jvm",
    "/usr/java",
    "/usr/local/java",
    "/usr/local/lib/jvm",
    vim.fn.expand("~/.sdkman/candidates/java"),
    vim.fn.expand("~/.jdks"),
    vim.fn.expand("~/.gradle/jdks"),
    vim.fn.expand("~/.asdf/installs/java"),
  }
  for _, root in ipairs(opts.roots or {}) do
    roots[#roots + 1] = root
  end
  for _, root in ipairs(roots) do
    consider_dir(homes, seen, root)
    local nested = vim.fn.glob(vim.fn.expand(root) .. "/*", true, true)
    for _, child in ipairs(nested) do
      consider_dir(homes, seen, child)
    end
  end

  local opt_globs = { "/opt/java*", "/opt/jdk*", "/opt/java/*", "/opt/jdk/*" }
  for _, pattern in ipairs(opt_globs) do
    for _, match in ipairs(vim.fn.glob(pattern, true, true)) do
      consider_dir(homes, seen, match)
    end
  end

  return homes
end

local cached_ok = false
local cached

function M.find(opts)
  if opts == nil and cached_ok then
    return cached
  end

  local function classify(home, usable, project, older, runtimes)
    local bin = M.executable(home)
    if not bin then
      return
    end
    local item = { home = home, bin = bin, major = M.major(bin) }
    if not is_jdk(home) then
      runtimes[#runtimes + 1] = item
    elseif not item.major or item.major < PROJECT_MIN then
      older[#older + 1] = item
    elseif item.major < LAUNCHER_MIN then
      project[#project + 1] = item
    else
      usable[#usable + 1] = item
    end
  end

  local usable = {}
  local project = {}
  local older = {}
  local runtimes = {}
  for _, home in ipairs(collect(opts)) do
    classify(home, usable, project, older, runtimes)
  end

  if #usable == 0 and opts == nil then
    classify(home_from_login_shell(), usable, project, older, runtimes)
  end

  M.last_project = project
  M.last_older = older
  M.last_runtimes = runtimes

  local best
  for _, item in ipairs(usable) do
    if not best or (item.major or 0) > (best.major or 0) then
      best = item
    end
  end

  local result
  if best then
    local installed = {}
    for _, item in ipairs(usable) do
      installed[#installed + 1] = item
    end
    for _, item in ipairs(project) do
      installed[#installed + 1] = item
    end
    result = {
      home = best.home,
      bin = best.bin,
      major = best.major,
      installed = installed,
    }
  end

  if opts == nil then
    cached_ok = true
    cached = result
  end
  return result
end

function M.runtimes(found)
  local by_major = {}
  for _, item in ipairs(found.installed or {}) do
    if item.major and item.major >= 17 and not by_major[item.major] then
      by_major[item.major] = item.home
    end
  end
  if found.major and found.home and not by_major[found.major] then
    by_major[found.major] = found.home
  end

  local majors = {}
  for major in pairs(by_major) do
    majors[#majors + 1] = major
  end
  table.sort(majors)

  local default_major = by_major[17] and 17 or found.major
  local runtimes = {}
  for _, major in ipairs(majors) do
    runtimes[#runtimes + 1] = {
      name = "JavaSE-" .. major,
      path = by_major[major],
      default = major == default_major,
    }
  end
  if #runtimes == 0 and found.home then
    runtimes[1] = {
      name = found.major and ("JavaSE-" .. found.major) or "JavaSE",
      path = found.home,
      default = true,
    }
  end
  return runtimes
end

function M.missing_message()
  local parts = {
    "jdtls needs a JDK 25 or newer to start.",
    "Looked in JAVA_HOME, ~/.local/nvim-tools/jdk, /usr/lib/jvm, /usr/bin/java, and your login shell.",
  }
  local project = M.last_project or {}
  local older = M.last_older or {}
  local runtimes = M.last_runtimes or {}
  if project[1] then
    parts[#parts + 1] = "Found Java "
      .. tostring(project[1].major)
      .. " at "
      .. project[1].home
      .. ". That JDK can build the project, but this jdtls build is compiled for Java 25."
  elseif older[1] then
    parts[#parts + 1] = "Found Java "
      .. tostring(older[1].major)
      .. " at "
      .. older[1].home
      .. ", which is too old for jdtls."
  elseif runtimes[1] then
    parts[#parts + 1] = "Found a Java runtime at " .. runtimes[1].home .. " without javac."
  end
  parts[#parts + 1] = "Re-run the installer, or install a JDK 25. Leave any older JDK in place so projects can keep using it."
  return table.concat(parts, " ")
end

return M
