vim.keymap.set('n', '<C-s>', '<cmd>write<CR>', { silent = true })
vim.keymap.set('i', '<C-s>', '<Esc><cmd>write<CR>a', { silent = true })

-- Insert only: Opt/Alt + Backspace — delete word before cursor (same as i_CTRL-W).
vim.keymap.set('i', '<M-BS>', '<C-W>', { silent = true })

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR><Esc>', { silent = true })
vim.keymap.set('n', 'Q', '<Nop>', { desc = 'Disable Ex mode (Q)' })

vim.keymap.set('n', '<leader>sr', ':%s///g<Left><Left><Left>', { desc = 'Find and replace in buffer' })
vim.keymap.set('x', '<leader>sr', ':s///g<Left><Left><Left>', { desc = 'Find and replace in selection' })
vim.keymap.set('n', 'ZX', '<cmd>qa!<CR>', {
  silent = true,
  desc = 'Quit all windows/tabs, discard unsaved buffers (:qa!)',
})

for _, key in ipairs({ 'u', 'd', 'f', 'b' }) do
  vim.keymap.set('n', '<C-' .. key .. '>', '<C-' .. key .. '>zz', { silent = true })
end
for _, key in ipairs({ 'n', 'N' }) do
  vim.keymap.set('n', key, key .. 'zzzv')
end

vim.keymap.set('n', ']x', '/<<<<<<<CR>', { silent = true, desc = 'Next conflict marker' })
vim.keymap.set('n', '[x', '?<<<<<<<CR>', { silent = true, desc = 'Previous conflict marker' })

vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")

vim.api.nvim_create_user_command('MyTips', function()
  local path = vim.fs.joinpath(vim.fn.stdpath('config'), 'nvim_tips.md')
  if vim.fn.filereadable(path) == 0 then
    vim.notify('MyTips: file not found: ' .. path, vim.log.levels.ERROR)
    return
  end
  vim.cmd('belowright split ' .. vim.fn.fnameescape(path))
end, { desc = 'Open nvim_tips.md below current window' })

-- Git (vim-fugitive)
vim.keymap.set('n', '<leader>gs', '<cmd>Git<CR>', { silent = true, desc = 'Git status (Fugitive)' })
vim.keymap.set('n', '<leader>gd', '<cmd>Gvdiffsplit<CR>', { silent = true, desc = 'Git vertical diff (same as dv in :Git)' })
vim.keymap.set('n', '<leader>gD', '<cmd>Gvdiffsplit HEAD<CR>', { silent = true, desc = 'Git vertical diff vs last commit' })
vim.keymap.set('n', '<leader>gb', '<cmd>Git blame<CR>', { silent = true, desc = 'Git blame (Fugitive)' })
local function git_line_range()
  if vim.fn.visualmode() ~= '' then
    local l1, l2 = vim.api.nvim_buf_get_mark(0, '<')[1], vim.api.nvim_buf_get_mark(0, '>')[1]
    if l1 > l2 then
      l1, l2 = l2, l1
    end
    return l1, l2
  end
  local line = vim.fn.line('.')
  return line, line
end

vim.keymap.set('n', '<leader>gl', '<cmd>Git log -- %<CR>', { silent = true, desc = 'Git log current file (Fugitive)' })
vim.keymap.set({ 'n', 'x' }, '<leader>gB', function()
  local l1, l2 = git_line_range()
  vim.cmd(('Git blame -L %d,%d -- %%'):format(l1, l2))
end, { silent = true, desc = 'Git blame line or visual selection (Fugitive)' })
vim.keymap.set({ 'n', 'x' }, '<leader>gL', function()
  local l1, l2 = git_line_range()
  vim.cmd(('Git log -L %d,%d:%%'):format(l1, l2))
end, { silent = true, desc = 'Git log line or visual selection (Fugitive)' })

vim.keymap.set('n', '=ap', "ma=ap'a")

local function close_terminal_window(buf)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == buf then
      vim.api.nvim_win_close(win, true)
      return true
    end
  end
  return false
end

vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

local function setup_leader_t_terminal(buf)
  vim.b[buf].leader_t_terminal = true

  vim.keymap.set('n', 'q', function()
    close_terminal_window(buf)
  end, { buffer = buf, desc = 'Close terminal window' })
end

vim.api.nvim_create_autocmd('TermOpen', {
  callback = function(event)
    if not vim.b.leader_t_terminal then
      return
    end
    vim.b.leader_t_terminal = nil
    setup_leader_t_terminal(event.buf)
  end,
})

vim.api.nvim_create_autocmd('TermClose', {
  callback = function(event)
    if not vim.b[event.buf].leader_t_terminal then
      return
    end
    vim.schedule(function()
      close_terminal_window(event.buf)
    end)
  end,
})

vim.keymap.set('n', '<leader>t', function()
  vim.cmd.vnew()
  vim.b.leader_t_terminal = true
  vim.cmd.term()
  vim.cmd.startinsert()
end, { desc = 'Terminal (bottom split)' })
