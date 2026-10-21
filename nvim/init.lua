vim.g.mapleader = ' '
vim.env.NVIM_LOG_FILE = vim.fn.stdpath('state') .. '/nvim.log'

if vim.uv.os_uname().sysname == 'Windows_NT' and vim.fn.executable('cl') ~= 1 then
  if vim.fn.executable('gcc') == 1 then
    vim.env.CC = vim.env.CC or 'gcc'
  end
  if vim.fn.executable('g++') == 1 then
    vim.env.CXX = vim.env.CXX or 'g++'
  end
end

local data_path = vim.fn.stdpath('data')
local path_sep = package.config:sub(1, 1)
local lazypath = table.concat({ data_path, 'lazy', 'lazy.nvim' }, path_sep)

if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
end

vim.opt.runtimepath:prepend(lazypath)

require('lazy').setup(require('plugins'), {
  checker = { enabled = false },
  rocks = { enabled = false },
})

require('core.options')
require('core.keymaps')
require('plugins.telescope')
require('core.lsp')
require('ui.colors')
