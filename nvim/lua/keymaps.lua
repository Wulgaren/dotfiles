vim.keymap.set('n', '<C-s>', '<cmd>write<CR>', { silent = true })
vim.keymap.set('i', '<C-s>', '<Esc><cmd>write<CR>a', { silent = true })

--------------------------------------------------------------------------------
-- Insert only: Opt/Alt + Backspace — delete word before cursor (same as i_CTRL-W).
-- Terminal must send Meta+Backspace / Meta+Del as chords (e.g. iTerm: Option → Esc+ or Meta).
--------------------------------------------------------------------------------
vim.keymap.set('i', '<M-BS>', '<C-W>', { silent = true })
vim.keymap.set('i', '<M-Del>', '<C-W>', { silent = true })

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR><Esc>', { silent = true })
vim.keymap.set('n', 'Q', '<Nop>', { desc = 'Disable Ex mode (Q)' })

vim.keymap.set('n', '<leader>sr', ':%s///g<Left><Left><Left>', { desc = 'Find and replace in buffer' })
vim.keymap.set('x', '<leader>sr', ':s///g<Left><Left><Left>', { desc = 'Find and replace in selection' })
vim.keymap.set('n', 'ZX', '<cmd>qa!<CR>', {
  silent = true,
  desc = 'Quit all windows/tabs, discard unsaved buffers (:qa!)',
})

vim.keymap.set('n', '<C-u>', '<C-u>zz', { silent = true })
vim.keymap.set('n', '<C-d>', '<C-d>zz', { silent = true })
vim.keymap.set('n', '<C-f>', '<C-f>zz', { silent = true })
vim.keymap.set('n', '<C-b>', '<C-b>zz', { silent = true })

vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

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

local function fugitive_smart_vdiff()
  if vim.fn.FugitiveGitDir() == '' then
    vim.notify('Fugitive: not in a Git repository buffer', vim.log.levels.WARN)
    return
  end
  local wt = vim.fn.FugitiveWorkTree()
  local relpath = vim.fn.FugitivePath(vim.fn.expand('%'), ':(top)')
  if relpath == '' or wt == '' then
    vim.notify('Fugitive: could not resolve file path in repo', vim.log.levels.WARN)
    return
  end
  local function diff_dirty(cached)
    local cmd = { 'git', '-C', wt, 'diff', '--quiet' }
    if cached then
      table.insert(cmd, '--cached')
    end
    vim.list_extend(cmd, { '--', relpath })
    vim.fn.system(cmd)
    return vim.v.shell_error ~= 0
  end
  local has_unstaged = diff_dirty(false)
  local has_staged = diff_dirty(true)
  if has_unstaged and has_staged then
    vim.ui.select({
      { label = 'Working tree vs HEAD (all changes)', cmd = 'Gvdiffsplit HEAD' },
      { label = 'Index vs working tree (staged vs unstaged)', cmd = 'Gvdiffsplit' },
    }, {
      prompt = 'Diff this file',
      format_item = function(item)
        return item.label
      end,
    }, function(item)
      if item then
        vim.cmd(item.cmd)
      end
    end)
  elseif has_staged and not has_unstaged then
    vim.cmd('Gvdiffsplit HEAD')
  else
    vim.cmd('Gvdiffsplit')
  end
end

vim.keymap.set('n', '<leader>gd', fugitive_smart_vdiff, { silent = true, desc = 'Git vertical diff (smart)' })
vim.keymap.set('n', '<leader>gb', '<cmd>Git blame<CR>', { silent = true, desc = 'Git blame (Fugitive)' })
vim.keymap.set('n', '<leader>gl', '<cmd>Git log -- %<CR>', { silent = true, desc = 'Git log current file (Fugitive)' })
vim.keymap.set('n', '<leader>gB', function()
  local line = vim.fn.line('.')
  vim.cmd(('Git blame -L %d,%d -- %%'):format(line, line))
end, { silent = true, desc = 'Git blame current line (Fugitive)' })
vim.keymap.set('n', '<leader>gL', function()
  local line = vim.fn.line('.')
  vim.cmd(('Git log -L %d,%d:%%'):format(line, line))
end, { silent = true, desc = 'Git log current line (Fugitive)' })

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
  vim.cmd.wincmd('J')
  vim.cmd.startinsert()
end, { desc = 'Terminal (bottom split)' })
