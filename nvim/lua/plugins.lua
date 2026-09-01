vim.pack.add({
  'https://github.com/mason-org/mason.nvim',
  'https://github.com/monkoose/neocodeium',
  'https://github.com/tpope/vim-fugitive',
  'https://github.com/m4xshen/hardtime.nvim'
}, { confirm = false, load = true })

require('hardtime').setup()
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
vim.keymap.set('i', '<M-y>', neocodeium.accept_word, { silent = true, desc = 'NeoCodeium: accept word' })
vim.keymap.set('i', '<M-u>', neocodeium.accept, { silent = true, desc = 'NeoCodeium: accept all' })
