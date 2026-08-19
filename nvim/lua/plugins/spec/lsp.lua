return {
    {
        'mason-org/mason.nvim',
        cmd = { 'Mason', 'MasonInstall', 'MasonUpdate', 'MasonLog' },
        opts = {
            registries = {
                'github:mason-org/mason-registry',
                'github:Crashdummyy/mason-registry',
            },
        },
    },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    dependencies = { 'mason-org/mason.nvim' },
    opts = {
      -- Install LSP servers used by core/lsp.lua.
      ensure_installed = {
        'bash-language-server',
        'css-lsp',
        'gopls',
        'html-lsp',
        'json-lsp',
        'lua-language-server',
        'python-lsp-server',
        'roslyn',
        'tailwindcss-language-server',
        'taplo',
        'typescript-language-server',
        'yaml-language-server',
      },
      run_on_start = true,
      start_delay = 3000,
      auto_update = false,
    },
  },
}

