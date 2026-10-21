local has_autocomplete_opt = pcall(vim.api.nvim_get_option_info2, 'autocomplete', {})
local platform = require('core.platform')

vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.mouse = 'a'
vim.opt.clipboard = 'unnamedplus'
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.updatetime = 250
vim.opt.signcolumn = 'yes'
vim.opt.completeopt = { 'menu', 'menuone', 'noselect', 'popup' }
vim.opt.pumheight = 12
if has_autocomplete_opt then
  vim.opt.autocomplete = false
end

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.tabstop = 8
vim.opt.softtabstop = 8
vim.opt.shiftwidth = 8
vim.opt.smartindent = true
vim.opt.expandtab = true
vim.opt.incsearch = true
vim.opt.wrap = false
vim.opt.winborder = "rounded"

-- Windows: CRLF files mis-read as unix show trailing ^M. Prefer dos; re-read if first lines contain CR.
if platform.is_windows then
  vim.opt.fileformats = { 'dos', 'unix', 'mac' }

  vim.api.nvim_create_autocmd('BufReadPost', {
    group = vim.api.nvim_create_augroup('config-windows-crlf', { clear = true }),
    callback = function()
      if vim.bo.fileformat ~= 'unix' or vim.bo.binary or vim.bo.buftype ~= '' then
        return
      end
      local last = math.min(50, vim.api.nvim_buf_line_count(0)) - 1
      for i = 0, math.max(last, 0) do
        local line = vim.api.nvim_buf_get_lines(0, i, i + 1, false)[1]
        if line and line:find('\r', 1, true) then
          vim.cmd('noautocmd silent edit ++ff=dos')
          return
        end
      end
    end,
  })
end

local options_autocmd_group = vim.api.nvim_create_augroup('config-options-autocmds', { clear = true })

vim.api.nvim_create_autocmd('FileType', {
  group = options_autocmd_group,
  pattern = 'qf',
  callback = function()
    -- Quickfix entries can be long; wrap instead of forcing horizontal scroll.
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
  end,
})

vim.api.nvim_create_autocmd('TextYankPost', {
  group = options_autocmd_group,
  callback = function()
    vim.highlight.on_yank()
  end,
})


--------------
--- MACROS ---
--------------
local esc = vim.api.nvim_replace_termcodes('<Esc>', true, true, true)
vim.fn.setreg("l", "yoconsole.log('" .. esc .. "pa: '" .. esc .. "a, " .. esc .. "pa)" .. esc .. "l")
