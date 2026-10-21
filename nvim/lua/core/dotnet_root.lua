--- Upward search for .NET project/solution markers.
--- vim.fs.find globs like "*.vbproj" do not work reliably on all platforms.
local M = {}

local function parent_dir(dir)
  local parent = vim.fs.dirname(dir)
  if parent == dir then
    return nil
  end
  return parent
end

---@param path string File path to search upward from
---@param suffixes string[] Filename suffixes, e.g. { '.vbproj', '.sln' }
---@return string? dir
---@return string? marker Full path to matched marker file
function M.find_up(path, suffixes)
  local dir = path ~= '' and vim.fs.dirname(path) or vim.fn.getcwd()
  while dir do
    for entry, typ in vim.fs.dir(dir) do
      if typ == 'file' then
        for _, suffix in ipairs(suffixes) do
          if vim.endswith(entry, suffix) then
            return dir, vim.fs.joinpath(dir, entry)
          end
        end
      end
    end
    dir = parent_dir(dir)
  end
end

---@param dir string
---@return string? sln_path Prefer non-test solution in dir
function M.sln_in_dir(dir)
  local solutions = {}
  for entry, typ in vim.fs.dir(dir) do
    if typ == 'file' and (vim.endswith(entry, '.sln') or vim.endswith(entry, '.slnx') or vim.endswith(entry, '.slnf')) then
      solutions[#solutions + 1] = vim.fs.joinpath(dir, entry)
    end
  end
  table.sort(solutions)
  for _, sln in ipairs(solutions) do
    if not sln:lower():find('test', 1, true) then
      return sln
    end
  end
  return solutions[1]
end

--- Workspace root for VB grep fallback: nearest vbproj or solution, not monorepo .git.
---@param path string
---@return string
function M.vb_root(path)
  local _, vbproj = M.find_up(path, { '.vbproj' })
  if vbproj then
    local sln_dir = M.find_up(vbproj, { '.sln', '.slnx', '.slnf' })
    if sln_dir then
      return sln_dir
    end
    return vim.fs.dirname(vbproj)
  end

  local sln_dir = M.find_up(path, { '.sln', '.slnx', '.slnf' })
  if sln_dir then
    return sln_dir
  end

  return vim.fn.getcwd()
end

--- Workspace root for C# / Roslyn.
---@param path string
---@return string
function M.roslyn_root(path)
  local sln_dir = M.find_up(path, { '.sln', '.slnx', '.slnf' })
  if sln_dir then
    return sln_dir
  end

  local _, csproj = M.find_up(path, { '.csproj' })
  if csproj then
    return vim.fs.dirname(csproj)
  end

  local git_dir = M.find_up(path, { '.git' })
  if git_dir then
    return git_dir
  end

  return vim.fn.getcwd()
end

return M
