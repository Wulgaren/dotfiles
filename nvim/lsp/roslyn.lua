--- C# via native vim.lsp.config + Mason `roslyn` (Crashdummyy registry).
---@type vim.lsp.Config
local fs = vim.fs
local dotnet_root = require('core.dotnet_root')

local function mason_roslyn_cmd()
  local package_dir = fs.joinpath(vim.fn.stdpath('data'), 'mason', 'packages', 'roslyn', 'libexec')
  local dll = fs.joinpath(package_dir, 'Microsoft.CodeAnalysis.LanguageServer.dll')
  -- Prefer `dotnet` over Mason's native apphost: on macOS arm64 the apphost often
  -- looks at /usr/local/share/dotnet (x64-only) while Homebrew dotnet lives elsewhere.
  if vim.uv.fs_stat(dll) and vim.fn.executable('dotnet') == 1 then
    return { 'dotnet', dll, '--stdio' }
  end

  local bin = fs.joinpath(vim.fn.stdpath('data'), 'mason', 'bin')
  local names = { 'roslyn-language-server', 'roslyn' }
  if vim.fn.has('win32') == 1 then
    names = { 'roslyn-language-server.exe', 'roslyn-language-server', 'roslyn.cmd', 'roslyn' }
  end
  for _, name in ipairs(names) do
    local path = fs.joinpath(bin, name)
    if vim.fn.executable(path) == 1 then
      return { path, '--stdio' }
    end
  end
end

local function dotnet_root_for_buf(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  return dotnet_root.roslyn_root(path)
end

local function choose_solution(targets)
  for _, t in ipairs(targets) do
    local lower = t:lower()
    if vim.endswith(t, '.sln') or vim.endswith(t, '.slnx') or vim.endswith(t, '.slnf') then
      if not lower:find('test', 1, true) then
        return t
      end
    end
  end
  for _, t in ipairs(targets) do
    if not t:lower():find('test', 1, true) then
      return t
    end
  end
  return targets[1]
end

local function solutions_in_dir(root_dir)
  local out = {}
  for entry, typ in fs.dir(root_dir) do
    if typ == 'file' and (vim.endswith(entry, '.sln') or vim.endswith(entry, '.slnx') or vim.endswith(entry, '.slnf')) then
      out[#out + 1] = fs.joinpath(root_dir, entry)
    end
  end
  table.sort(out)
  return out
end

local cmd = mason_roslyn_cmd()

return vim.tbl_extend('force', {
  filetypes = { 'cs' },
  root_dir = function(bufnr, on_dir)
    on_dir(dotnet_root_for_buf(bufnr))
  end,
  on_init = {
    function(client)
      local root_dir = client.config.root_dir
      if not root_dir then
        return
      end

      local solutions = solutions_in_dir(root_dir)
      if #solutions > 0 then
        local target = choose_solution(solutions)
        vim.notify('Roslyn: ' .. vim.fn.fnamemodify(target, ':t'), vim.log.levels.INFO, { title = 'roslyn' })
        ---@diagnostic disable-next-line: param-type-mismatch
        client:notify('solution/open', { solution = vim.uri_from_fname(target) })
        return
      end

      local projects = {}
      for entry, typ in fs.dir(root_dir) do
        if typ == 'file' and vim.endswith(entry, '.csproj') then
          projects[#projects + 1] = vim.uri_from_fname(fs.joinpath(root_dir, entry))
        end
      end
      if #projects > 0 then
        ---@diagnostic disable-next-line: param-type-mismatch
        client:notify('project/open', { projects = projects })
      end
    end,
  },
}, cmd and { cmd = cmd } or {})
