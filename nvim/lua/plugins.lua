vim.pack.add({
  'https://github.com/mason-org/mason.nvim',
  'https://github.com/monkoose/neocodeium',
  'https://github.com/tpope/vim-fugitive',
}, { confirm = false, load = true })

require('mason').setup({
  registries = {
    'github:mason-org/mason-registry',
    'github:Crashdummyy/mason-registry',
  },
})
local mason_bin = vim.fn.stdpath('data') .. '/mason/bin'
vim.env.PATH = mason_bin .. ':' .. vim.env.PATH

local neocodeium = require('neocodeium')
neocodeium.setup({
  filetypes = {
    TelescopePrompt = false,
  },
})
vim.keymap.set('n', '<leader>ko', '<cmd>NeoCodeium toggle<CR>', {
  silent = true,
  desc = 'NeoCodeium toggle (no bang; use :NeoCodeium! toggle to halt server)',
})
--- Full suggestion accept (`accept`, not word). `<M-Tab>` = Alt+Tab; OS may capture it before Neovim.
vim.keymap.set('i', '<M-Tab>', neocodeium.accept, { silent = true, desc = 'NeoCodeium: accept all' })
vim.keymap.set('i', '<M-w>', neocodeium.accept_word, { silent = true, desc = 'NeoCodeium: accept word' })
vim.keymap.set('i', '<M-l>', neocodeium.accept_line, { silent = true, desc = 'NeoCodeium: accept line' })
vim.keymap.set('i', '<Tab>', function()
  if neocodeium.visible() then
    neocodeium.accept_word()
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Tab>', true, false, true), 'n', true)
  end
end, { silent = true, desc = 'NeoCodeium: accept word, else insert Tab' })
