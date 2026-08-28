--- Upward search for .NET project/solution markers.
--- vim.fs.find globs like "*.vbproj" do not work reliably on all platforms.
local M = {}

local SLN = { '.sln', '.slnx', '.slnf' }

local function parent(dir)
  local p = vim.fs.dirname(dir)
  return p ~= dir and p or nil
end

local function ends_with(name, suffixes)
  for _, suffix in ipairs(suffixes) do
    if vim.endswith(name, suffix) then
      return true
    end
  end
end

---@param path string File path to search upward from
---@param suffixes string[] Filename suffixes, e.g. { '.vbproj', '.sln' }
---@return string? dir
---@return string? marker Full path to matched marker file
function M.find_up(path, suffixes)
  local dir = path ~= '' and vim.fs.dirname(path) or vim.fn.getcwd()
  while dir do
    for entry, typ in vim.fs.dir(dir) do
      if typ == 'file' and ends_with(entry, suffixes) then
        return dir, vim.fs.joinpath(dir, entry)
      end
    end
    dir = parent(dir)
  end
end

---@param paths string[]
---@return string?
local function prefer_non_test(paths)
  table.sort(paths)
  for _, path in ipairs(paths) do
    if not path:lower():find('test', 1, true) then
      return path
    end
  end
  return paths[1]
end

---@param dir string
---@return string? sln_path Prefer non-test solution in dir
function M.sln_in_dir(dir)
  local solutions = {}
  for entry, typ in vim.fs.dir(dir) do
    if typ == 'file' and ends_with(entry, SLN) then
      solutions[#solutions + 1] = vim.fs.joinpath(dir, entry)
    end
  end
  if #solutions > 0 then
    return prefer_non_test(solutions)
  end
end

--- Workspace root for C# / Roslyn.
---@param path string
---@return string
function M.roslyn_root(path)
  local sln_dir = M.find_up(path, SLN)
  if sln_dir then
    return sln_dir
  end

  local _, csproj = M.find_up(path, { '.csproj' })
  if csproj then
    return vim.fs.dirname(csproj)
  end

  return M.find_up(path, { '.git' }) or vim.fn.getcwd()
end

return M
