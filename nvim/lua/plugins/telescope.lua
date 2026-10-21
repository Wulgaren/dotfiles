local has_autocomplete_opt = pcall(vim.api.nvim_get_option_info2, 'autocomplete', {})
local telescope_ok, telescope = pcall(require, 'telescope')
local telescope_actions = telescope_ok and require('telescope.actions') or nil
local telescope_builtin = telescope_ok and require('telescope.builtin') or nil
local telescope_themes = telescope_ok and require('telescope.themes') or nil
local telescope_sorters = telescope_ok and require('telescope.sorters') or nil

if not telescope_ok then
  return
end

local TELESCOPE_RG_EXCLUDE_GLOBS = {
  '!.git',
  '!**/.git/**',
  '!**/node_modules/**',
  '!**/dist/**',
  '!**/build/**',
  '!**/.cache/**',
  '!**/bin/**',
  '!**/obj/**',
  '!**/*.min.*',
  '!**/*.d.ts',
  '!**/*.g.cs',
  '!**/wwwroot/lib/**',
  '!**/*syncfusion*',
  '!**/jquery*.js',
  '!**/jquery*.map',
  '!**/bootstrap/**',
  '!**/tests/mocks/**',
}

local function telescope_rg_glob_cli_args()
  local args = {}
  for _, g in ipairs(TELESCOPE_RG_EXCLUDE_GLOBS) do
    table.insert(args, '-g')
    table.insert(args, g)
  end
  return args
end

local function space_insensitive_fzy_sorter()
  local base = telescope_sorters.get_fzy_sorter()
  return telescope_sorters.Sorter:new({
    discard = true,
    scoring_function = function(_, prompt, line, ...)
      -- Treat spaces in prompt as optional so "my file" matches "myfile".
      local collapsed = (prompt or ''):gsub('%s+', '')
      if collapsed == '' then
        return 1
      end
      return base.scoring_function(_, collapsed, line, ...)
    end,
    highlighter = function(_, prompt, display)
      local collapsed = (prompt or ''):gsub('%s+', '')
      if collapsed == '' then
        return {}
      end
      return base.highlighter(_, collapsed, display)
    end,
  })
end

telescope.setup({
  defaults = {
    prompt_prefix = '  ',
    selection_caret = '  ',
    sorting_strategy = 'ascending',
    wrap_results = true,
    file_sorter = space_insensitive_fzy_sorter,
    generic_sorter = space_insensitive_fzy_sorter,
    layout_config = {
      prompt_position = 'top',
    },
    mappings = {
      i = {
        ['<Esc>'] = telescope_actions.close,
      },
    },
  },
  pickers = {
    live_grep = {
      additional_args = function()
        local args = { '-i', '--fixed-strings' }
        vim.list_extend(args, telescope_rg_glob_cli_args())
        return args
      end,
    },
  },
})

local function telescope_files()
  local find_cmd = { 'rg', '--files', '--hidden' }
  vim.list_extend(find_cmd, telescope_rg_glob_cli_args())
  telescope_builtin.find_files(telescope_themes.get_dropdown({
    previewer = false,
    hidden = true,
    cwd = vim.fn.getcwd(),
    find_command = find_cmd,
  }))
end

local LIVE_GREP_OPTS = {
  cwd = vim.fn.getcwd(),
  layout_strategy = 'horizontal',
  layout_config = {
    width = 0.95,
    height = 0.9,
    preview_width = 0.55,
    prompt_position = 'top',
  },
  mappings = {
    i = {
      ['<CR>'] = telescope_actions.select_default + telescope_actions.center,
    },
    n = {
      ['<CR>'] = telescope_actions.select_default + telescope_actions.center,
    },
  },
}

local function telescope_live_grep_opts(extra)
  local opts = vim.deepcopy(LIVE_GREP_OPTS)
  opts.cwd = vim.fn.getcwd()
  if extra then
    for k, v in pairs(extra) do
      opts[k] = v
    end
  end
  return opts
end

local function telescope_live_grep()
  telescope_builtin.live_grep(telescope_live_grep_opts({}))
end

local function git_worktree()
  local fugitive_dir = vim.fn.FugitiveGitDir()
  if fugitive_dir ~= '' then
    return vim.fn.fnamemodify(fugitive_dir, ':h')
  end
  local wt = vim.fn.systemlist({ 'git', 'rev-parse', '--show-toplevel' })[1]
  if vim.v.shell_error == 0 and wt ~= '' then
    return wt
  end
  return nil
end

local function normalize_branch_ref(ref)
  return ref:gsub('^remotes/origin/', ''):gsub('^origin/', '')
end

local function branch_name_from_prompt(prompt)
  return vim.trim(prompt or ''):gsub('%s+', '_')
end

local function local_branch_exists(worktree, branch)
  vim.fn.system({ 'git', '-C', worktree, 'show-ref', '--verify', '--quiet', 'refs/heads/' .. branch })
  return vim.v.shell_error == 0
end

local function remote_branch_exists(worktree, branch)
  vim.fn.system({ 'git', '-C', worktree, 'show-ref', '--verify', '--quiet', 'refs/remotes/origin/' .. branch })
  return vim.v.shell_error == 0
end

local function branch_has_upstream(worktree)
  vim.fn.system({ 'git', '-C', worktree, 'rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{u}' })
  return vim.v.shell_error == 0
end

local function ensure_upstream(worktree, branch)
  if not remote_branch_exists(worktree, branch) or branch_has_upstream(worktree) then
    return
  end

  local err = vim.fn.system({
    'git',
    '-C',
    worktree,
    'branch',
    '--set-upstream-to=origin/' .. branch,
    branch,
  })
  if vim.v.shell_error ~= 0 then
    vim.notify('Telescope: failed to set upstream: ' .. vim.trim(err), vim.log.levels.WARN)
  end
end

local function switch_to_branch(worktree, branch)
  if local_branch_exists(worktree, branch) then
    local err = vim.fn.system({ 'git', '-C', worktree, 'switch', branch })
    if vim.v.shell_error ~= 0 then
      return 'Telescope: failed to switch branch: ' .. vim.trim(err)
    end
    ensure_upstream(worktree, branch)
    return nil
  end

  if remote_branch_exists(worktree, branch) then
    local err = vim.fn.system({ 'git', '-C', worktree, 'switch', '--track', 'origin/' .. branch })
    if vim.v.shell_error ~= 0 then
      return 'Telescope: failed to track remote branch: ' .. vim.trim(err)
    end
    return nil
  end

  return 'Telescope: branch not found locally or on origin: ' .. branch
end

local function git_branch_names(worktree)
  local lines = vim.fn.systemlist({
    'git',
    '-C',
    worktree,
    'branch',
    '-a',
    '--format=%(refname:short)',
  })
  if vim.v.shell_error ~= 0 then
    return nil
  end

  local seen = {}
  local branches = {}
  for _, ref in ipairs(lines) do
    local name = normalize_branch_ref(ref)
    if name ~= '' and name ~= 'HEAD' and not seen[name] then
      seen[name] = true
      branches[#branches + 1] = name
    end
  end
  table.sort(branches)
  return branches
end

local function telescope_git_branches()
  local worktree = git_worktree()
  if not worktree then
    vim.notify('Telescope: not in a Git repository', vim.log.levels.WARN)
    return
  end

  local branches = git_branch_names(worktree)
  if not branches then
    vim.notify('Telescope: failed to list Git branches', vim.log.levels.ERROR)
    return
  end

  local current = vim.fn.systemlist({ 'git', '-C', worktree, 'branch', '--show-current' })[1] or ''
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local conf = require('telescope.config').values
  local finders = require('telescope.finders')
  local pickers = require('telescope.pickers')

  pickers.new({}, {
    prompt_title = 'Git Branches (create on Enter if no match)',
    finder = finders.new_table({
      results = branches,
      entry_maker = function(name)
        local marker = name == current and '* ' or '  '
        return {
          value = name,
          display = marker .. name,
          ordinal = name,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(_, map)
      local function switch_or_create_branch(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        local prompt = action_state.get_current_line()

        if entry and entry.value then
          actions.close(prompt_bufnr)
          local err = switch_to_branch(worktree, entry.value)
          if err then
            vim.notify(err, vim.log.levels.ERROR)
          end
          return
        end

        local branch = branch_name_from_prompt(prompt)
        if branch == '' then
          return
        end

        actions.close(prompt_bufnr)
        local err = vim.fn.system({ 'git', '-C', worktree, 'switch', '-c', branch })
        if vim.v.shell_error ~= 0 then
          vim.notify('Telescope: failed to create branch: ' .. vim.trim(err), vim.log.levels.ERROR)
        else
          vim.notify('Created and switched to: ' .. branch, vim.log.levels.INFO)
        end
      end
      map('i', '<CR>', switch_or_create_branch)
      map('n', '<CR>', switch_or_create_branch)
      return true
    end,
  }):find()
end

local telescope_autocmd_group = vim.api.nvim_create_augroup('config-telescope-autocmds', { clear = true })

vim.keymap.set('n', '<C-p>', telescope_files, { silent = true, desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', telescope_live_grep, { silent = true, desc = 'Telescope live grep' })
vim.keymap.set('n', '<C-t>', telescope_live_grep, { silent = true, desc = 'Telescope live grep' })
vim.keymap.set('n', '<C-j>', telescope_builtin.buffers, { silent = true, desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>b', telescope_builtin.buffers, { silent = true, desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>gc', telescope_git_branches, { silent = true, desc = 'Git switch branch' })
vim.keymap.set('n', '<leader>fs', telescope_builtin.lsp_document_symbols, { silent = true, desc = 'Telescope LSP document symbols' })
vim.keymap.set('n', '<C-h>', telescope_builtin.marks, { silent = true, desc = 'Telescope marks' })

vim.api.nvim_create_autocmd('FileType', {
  group = telescope_autocmd_group,
  pattern = 'TelescopePrompt',
  callback = function()
    if has_autocomplete_opt then
      vim.opt_local.autocomplete = false
    end
  end,
})

vim.api.nvim_create_autocmd('User', {
  group = telescope_autocmd_group,
  pattern = 'TelescopePreviewerLoaded',
  callback = function()
    -- Preview buffers can contain long lines; keep soft wrapping enabled.
    vim.wo.wrap = true
    vim.wo.linebreak = true
  end,
})

