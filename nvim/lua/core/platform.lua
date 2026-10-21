local M = {}

M.is_windows = vim.loop.os_uname().sysname == 'Windows_NT'
M.path_sep = package.config:sub(1, 1)

function M.join_path(...)
  return table.concat({ ... }, M.path_sep)
end

function M.home_dir()
  return vim.env.HOME or vim.env.USERPROFILE or vim.fn.expand('~')
end

function M.appdata_dir()
  return vim.env.APPDATA or ''
end

function M.editor_lsp_bin_dir()
  -- Optional manual install dir (not Mason); always a string so callers may join safely.
  if M.is_windows then
    return M.appdata_dir() .. '\\editor-lsp\\bin'
  end
  return M.join_path(M.home_dir(), '.local', 'share', 'editor-lsp', 'bin')
end

return M

