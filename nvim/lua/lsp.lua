-- lsp
vim.lsp.enable({
  'lua_ls',
  'ts_ls',
  'html',
  'cssls',
  'tailwindcss',
  'jsonls',
  'bashls',
  'pylsp',
  'roslyn',
})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client ~= nil and client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end

    local opts = { buffer = ev.buf, silent = true }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set({ 'n', 'v' }, '<leader>f', function()
      local format_opts = { async = false }
      if vim.fn.mode():match('^[vV\22]') then
        format_opts.range = {
          start = vim.api.nvim_buf_get_mark(0, '<'),
          ['end'] = vim.api.nvim_buf_get_mark(0, '>'),
        }
      end
      vim.lsp.buf.format(format_opts)
    end, vim.tbl_extend('force', opts, { desc = 'Format buffer or selection' }))
  end,
})

