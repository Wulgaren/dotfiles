vim.pack.add({
    'https://github.com/mason-org/mason.nvim',
    'https://github.com/nvim-treesitter/nvim-treesitter',
    'https://github.com/tpope/vim-fugitive',
    'https://github.com/monkoose/neocodeium',
    'https://github.com/m4xshen/hardtime.nvim',
    'https://codeberg.org/ficd/ashen.nvim',
    'https://github.com/catppuccin/nvim'
}, { confirm = false, load = true })

require('ashen').setup({
    transparent = true,
    plugins = {
        autoload = false
    },
    hl = {
        force_override = {
            DiffAdd = { "green_light", "g_9" },
            Added = { "green_light", nil },
            Pmenu = { "g_2" },
            PmenuSbar = { "g_8" },
            WildMenu = { "g_5" },
        },
    },
})
-- require('catppuccin').setup({ transparent_background = true })
require('ashen').load()

vim.api.nvim_create_autocmd('FileType', {
    callback = function()
        pcall(vim.treesitter.start)
    end,
})

local mason_bin = vim.fn.stdpath('data') .. '/mason/bin'
vim.env.PATH = mason_bin .. ':' .. vim.env.PATH

-- Manual installs (run once):
-- :lua require('mason').setup({ registries = { 'github:mason-org/mason-registry', 'github:Crashdummyy/mason-registry' } }); vim.cmd('MasonInstall bash-language-server css-lsp gopls html-lsp json-lsp lua-language-server python-lsp-server roslyn tailwindcss-language-server taplo typescript-language-server yaml-language-server'); require('nvim-treesitter').install({ 'bash', 'css', 'go', 'html', 'json', 'lua', 'python', 'c_sharp', 'toml', 'typescript', 'tsx', 'javascript', 'yaml' })

local neocodeium = require('neocodeium')
neocodeium.setup()
vim.keymap.set('i', '<M-y>', neocodeium.accept_word, { silent = true, desc = 'NeoCodeium: accept word' })
vim.keymap.set('i', '<M-u>', neocodeium.accept, { silent = true, desc = 'NeoCodeium: accept all' })

require('hardtime').setup()
