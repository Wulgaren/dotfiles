--- Swift (macOS): sourcekit-lsp ships with Xcode / Swift toolchain, not Mason.
--- cmd set in core/lsp.lua after resolving a local binary.
---@type vim.lsp.Config
return {
  filetypes = { 'swift' },
  root_dir = function(bufnr)
    local path = vim.api.nvim_buf_get_name(bufnr)
    if path == '' then
      return vim.fn.getcwd()
    end
    return vim.fs.root(path, { 'Package.swift', '.git' }) or vim.fn.getcwd()
  end,
}
