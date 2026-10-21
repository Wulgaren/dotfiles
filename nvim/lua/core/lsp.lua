local platform = require('core.platform')
local is_windows = platform.is_windows
local mason_bin = platform.join_path(vim.fn.stdpath('data'), 'mason', 'bin')
local lsp_bin = platform.editor_lsp_bin_dir()
local tailwind_markers = { 'tailwind.config.js', 'tailwind.config.cjs', 'tailwind.config.ts', 'package.json', '.git' }

local function join_path(...)
  return platform.join_path(...)
end

local function command_exists(cmd)
  return vim.fn.executable(cmd) == 1
end

local function first_available_command(candidates)
  for _, candidate in ipairs(candidates) do
    if command_exists(candidate[1]) then
      return candidate
    end
  end
  return nil
end

local function root_dir(bufnr, markers)
  local path = vim.api.nvim_buf_get_name(bufnr)
  return vim.fs.root(path, markers) or vim.fn.getcwd()
end

local function start_lsp(bufnr, name, cmd, markers, opts)
  if not cmd or not command_exists(cmd[1]) then
    return
  end
  local config = vim.tbl_deep_extend('force', {
    name = name,
    cmd = cmd,
    root_dir = root_dir(bufnr, markers),
  }, opts or {})
  vim.lsp.start(config)
end

local function html_lsp_cmd()
  if is_windows then
    return first_available_command({
      { mason_bin .. '\\html-lsp.cmd' },
      { lsp_bin .. '\\html-lsp.cmd' },
      { mason_bin .. '\\vscode-html-language-server.cmd', '--stdio' },
      { lsp_bin .. '\\vscode-html-language-server.cmd', '--stdio' },
    })
  end
  return first_available_command({
    { join_path(mason_bin, 'html-lsp'), '--stdio' },
    { join_path(mason_bin, 'vscode-html-language-server'), '--stdio' },
    { join_path(lsp_bin, 'vscode-html-language-server'), '--stdio' },
    { 'vscode-html-language-server', '--stdio' },
  })
end

local function css_lsp_cmd()
  if is_windows then
    return first_available_command({
      { mason_bin .. '\\css-lsp.cmd' },
      { lsp_bin .. '\\css-lsp.cmd' },
      { mason_bin .. '\\vscode-css-language-server.cmd', '--stdio' },
      { lsp_bin .. '\\vscode-css-language-server.cmd', '--stdio' },
    })
  end
  return first_available_command({
    { join_path(mason_bin, 'css-lsp'), '--stdio' },
    { join_path(mason_bin, 'vscode-css-language-server'), '--stdio' },
    { join_path(lsp_bin, 'vscode-css-language-server'), '--stdio' },
    { 'vscode-css-language-server', '--stdio' },
  })
end

local function tailwind_lsp_cmd()
  if is_windows then
    return first_available_command({
      { mason_bin .. '\\tailwindcss-language-server.cmd', '--stdio' },
      { lsp_bin .. '\\tailwind-lsp.cmd' },
      { lsp_bin .. '\\tailwindcss-language-server.cmd', '--stdio' },
    })
  end
  return first_available_command({
    { join_path(mason_bin, 'tailwindcss-language-server'), '--stdio' },
    { join_path(lsp_bin, 'tailwindcss-language-server'), '--stdio' },
    { 'tailwindcss-language-server', '--stdio' },
  })
end

local function ts_lsp_cmd()
  if is_windows then
    return first_available_command({
      { mason_bin .. '\\typescript-language-server.cmd', '--stdio' },
      { platform.appdata_dir() .. '\\npm\\typescript-language-server.cmd', '--stdio' },
      { lsp_bin .. '\\typescript-language-server.cmd', '--stdio' },
    })
  end
  return first_available_command({
    { join_path(mason_bin, 'typescript-language-server'), '--stdio' },
    { join_path(lsp_bin, 'typescript-language-server'), '--stdio' },
    { 'typescript-language-server', '--stdio' },
  })
end

local function lua_lsp_cmd()
  if is_windows then
    return first_available_command({
      { mason_bin .. '\\lua-language-server.exe' },
      { lsp_bin .. '\\lua-language-server.exe' },
      { 'lua-language-server.exe' },
      { 'lua-language-server' },
    })
  end
  return first_available_command({
    { join_path(mason_bin, 'lua-language-server') },
    { join_path(lsp_bin, 'lua-language-server') },
    { 'lua-language-server' },
  })
end

local function go_lsp_cmd()
  if is_windows then
    return first_available_command({
      { mason_bin .. '\\gopls.cmd' },
      { mason_bin .. '\\gopls.EXE' },
      { lsp_bin .. '\\gopls.cmd' },
      { lsp_bin .. '\\gopls.EXE' },
      { 'gopls' },
    })
  end
  return first_available_command({
    { join_path(mason_bin, 'gopls') },
    { join_path(lsp_bin, 'gopls') },
    { 'gopls' },
  })
end

-- sourcekit-lsp ships with Xcode / Swift toolchain (not in Mason). Optional manual symlinks in mason_bin / lsp_bin.
local function swift_lsp_cmd()
  if is_windows then
    return first_available_command({
      { join_path(mason_bin, 'sourcekit-lsp') },
      { join_path(lsp_bin, 'sourcekit-lsp') },
      { 'sourcekit-lsp' },
    })
  end
  local candidates = {
    { join_path(mason_bin, 'sourcekit-lsp') },
    { join_path(lsp_bin, 'sourcekit-lsp') },
  }
  if vim.fn.has('mac') == 1 then
    table.insert(candidates, {
      '/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp',
    })
    table.insert(candidates, {
      '/Library/Developer/CommandLineTools/usr/bin/sourcekit-lsp',
    })
  end
  table.insert(candidates, { 'sourcekit-lsp' })
  return first_available_command(candidates)
end

local function vb_grep_symbol(bufnr, word)
  word = word or vim.fn.expand('<cword>')
  if word == '' then
    return
  end
  local path = vim.api.nvim_buf_get_name(bufnr)
  local cwd = require('core.dotnet_root').vb_root(path)
  local ok, builtin = pcall(require, 'telescope.builtin')
  if ok then
    builtin.grep_string({
      search = word,
      cwd = cwd,
      glob_pattern = '*.vb',
      prompt_title = 'VB grep',
    })
  else
    vim.notify(('grep for "%s" in %s'):format(word, cwd), vim.log.levels.INFO)
  end
end

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local opts = { buffer = args.buf, silent = true }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gr', function()
      local ok, builtin = pcall(require, 'telescope.builtin')
      if ok then
        builtin.lsp_references()
      else
        vim.lsp.buf.references()
      end
    end, vim.tbl_extend('force', opts, { desc = 'LSP references (Telescope)' }))
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
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

local diag_severity = vim.diagnostic.severity

-- Nerd Font / Font Awesome PUA glyphs (terminal must use a patched font).
local function d_icon(codepoint)
  return vim.fn.nr2char(codepoint)
end

vim.diagnostic.config({
  -- Truncate EOL virtual_text so lines stay readable; full text via `<leader>dd` open_float.
  virtual_text = {
    spacing = 2,
    source = 'if_many',
    prefix = ' ',
    format = function(diagnostic)
      local msg = diagnostic.message:gsub('%s*\n%s*', ' '):gsub('%s+', ' ')
      local max_len = 72
      if #msg > max_len then
        return msg:sub(1, max_len - 1) .. '…'
      end
      return msg
    end,
  },
  -- 0.12+ uses extmark sign_text; sign_define() does not apply to these diagnostics.
  signs = {
    text = {
      [diag_severity.ERROR] = d_icon(0xf057),
      [diag_severity.WARN] = d_icon(0xf071),
      [diag_severity.INFO] = d_icon(0xf05a),
      [diag_severity.HINT] = d_icon(0xf7b5),
    },
  },
  underline = true,
  severity_sort = true,
  float = { border = 'rounded' },
})

do
  local default_publish = vim.lsp.handlers['textDocument/publishDiagnostics']
  vim.lsp.handlers['textDocument/publishDiagnostics'] = function(err, result, ctx, config)
    if result and result.uri then
      local bufnr = vim.uri_to_bufnr(result.uri)
      if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
        return
      end
    end
    return default_publish(err, result, ctx, config)
  end

  local default_pull = vim.lsp.handlers['textDocument/diagnostic']
  if default_pull then
    vim.lsp.handlers['textDocument/diagnostic'] = function(err, result, ctx, config)
      local bufnr = ctx and ctx.bufnr
      if not bufnr then
        return
      end
      bufnr = vim._resolve_bufnr(bufnr)
      if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
        return
      end
      -- Drop stale responses; avoids bufstate nil crash in vim.lsp.diagnostic.on_diagnostic (Nvim 0.12).
      if vim.tbl_isempty(vim.lsp.get_clients({ bufnr = bufnr, method = 'textDocument/diagnostic' })) then
        return
      end
      vim.lsp.diagnostic._enable(bufnr)
      return default_pull(err, result, ctx, config)
    end
  end
end

local lsp_autocmd_group = vim.api.nvim_create_augroup('config-lsp-autocmds', { clear = true })

vim.api.nvim_create_autocmd('FileType', {
  group = lsp_autocmd_group,
  pattern = { 'html' },
  callback = function(args)
    start_lsp(args.buf, 'html', html_lsp_cmd(), { 'package.json', '.git' })
    start_lsp(args.buf, 'tailwindcss', tailwind_lsp_cmd(), tailwind_markers)
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  group = lsp_autocmd_group,
  pattern = { 'css' },
  callback = function(args)
    start_lsp(args.buf, 'cssls', css_lsp_cmd(), { 'package.json', '.git' })
    start_lsp(args.buf, 'tailwindcss', tailwind_lsp_cmd(), tailwind_markers)
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  group = lsp_autocmd_group,
  pattern = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  callback = function(args)
    start_lsp(args.buf, 'ts_ls', ts_lsp_cmd(), { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' })
    start_lsp(args.buf, 'tailwindcss', tailwind_lsp_cmd(), tailwind_markers)
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  group = lsp_autocmd_group,
  pattern = { 'python' },
  callback = function(args)
    start_lsp(
      args.buf,
      'pylsp',
      first_available_command({
        { join_path(mason_bin, 'pylsp') },
        { 'pylsp' },
      }),
      { 'pyproject.toml', 'setup.py', 'requirements.txt', '.git' }
    )
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  group = lsp_autocmd_group,
  pattern = { 'sh', 'bash', 'zsh' },
  callback = function(args)
    local cmd = first_available_command({
      { join_path(mason_bin, 'bash-language-server'), 'start' },
      { 'bash-language-server', 'start' },
    })
    start_lsp(args.buf, 'bashls', cmd, { '.git' })
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  group = lsp_autocmd_group,
  pattern = { 'toml' },
  callback = function(args)
    local cmd = first_available_command({
      { join_path(mason_bin, 'taplo'), 'lsp', 'stdio' },
      { 'taplo', 'lsp', 'stdio' },
    })
    start_lsp(args.buf, 'taplo', cmd, { '.git' })
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  group = lsp_autocmd_group,
  pattern = { 'yaml' },
  callback = function(args)
    local cmd = first_available_command({
      { join_path(mason_bin, 'yaml-language-server'), '--stdio' },
      { 'yaml-language-server', '--stdio' },
    })
    start_lsp(args.buf, 'yamlls', cmd, { '.git' })
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  group = lsp_autocmd_group,
  pattern = { 'json', 'jsonc' },
  callback = function(args)
    local json_cmd = is_windows
      and first_available_command({
        { mason_bin .. '\\json-lsp.cmd', '--stdio' },
        { lsp_bin .. '\\vscode-json-language-server.cmd', '--stdio' },
      })
      or first_available_command({
        { join_path(mason_bin, 'json-lsp'), '--stdio' },
        { join_path(lsp_bin, 'vscode-json-language-server'), '--stdio' },
        { 'vscode-json-language-server', '--stdio' },
      })
    start_lsp(args.buf, 'jsonls', json_cmd, { 'package.json', '.git' })
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  group = lsp_autocmd_group,
  pattern = { 'go' },
  callback = function(args)
    start_lsp(args.buf, 'gopls', go_lsp_cmd(), { 'go.mod', 'go.work', '.git' })
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  group = lsp_autocmd_group,
  pattern = { 'swift' },
  callback = function(args)
    start_lsp(args.buf, 'sourcekit', swift_lsp_cmd(), { 'Package.swift', '*.xcodeproj', '.git' })
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  group = lsp_autocmd_group,
  pattern = { 'vb' },
  callback = function(args)
    local opts = { buffer = args.buf, silent = true }
    vim.keymap.set('n', 'gd', function()
      vb_grep_symbol(args.buf)
    end, vim.tbl_extend('force', opts, { desc = 'VB symbol grep' }))
    vim.keymap.set('n', 'gr', function()
      vb_grep_symbol(args.buf)
    end, vim.tbl_extend('force', opts, { desc = 'VB symbol grep' }))
    vim.keymap.set('n', '<leader>gw', function()
      vb_grep_symbol(args.buf)
    end, vim.tbl_extend('force', opts, { desc = 'VB symbol grep' }))
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  group = lsp_autocmd_group,
  pattern = { 'lua' },
  callback = function(args)
    start_lsp(args.buf, 'lua_ls', lua_lsp_cmd(), { '.luarc.json', '.luarc.jsonc', '.git' }, {
      settings = {
        Lua = {
          diagnostics = {
            globals = { 'vim' },
          },
          workspace = {
            checkThirdParty = false,
            library = vim.api.nvim_get_runtime_file('', true),
          },
        },
      },
    })
  end,
})

-- C# → roslyn (nvim/lsp/roslyn.lua)
vim.lsp.enable('roslyn')

-- Optional: other plugins that use :sign with DiagnosticSign* names.
for type, cp in pairs({
  Error = 0xf057,
  Warn = 0xf071,
  Hint = 0xf7b5,
  Info = 0xf05a,
}) do
  local hl = 'DiagnosticSign' .. type
  vim.fn.sign_define(hl, { text = d_icon(cp), texthl = hl, numhl = '' })
end
