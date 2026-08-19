return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      local parser_dir = vim.fn.stdpath('data') .. '/site'
      require('nvim-treesitter').setup({
        install_dir = parser_dir,
      })

      require('nvim-treesitter').install({
        'bash',
        'c_sharp',
        'css',
        'html',
        'javascript',
        'json',
        'lua',
        'markdown',
        'markdown_inline',
        'python',
        'query',
        'swift',
        'toml',
        'tsx',
        'typescript',
        'vim',
        'vimdoc',
        'yaml',
        'go'
      })
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    event = 'VeryLazy',
    config = function()
      require('nvim-treesitter-textobjects').setup({
        select = {
          enable = true,
          lookahead = true,
        },
        move = {
          enable = true,
          set_jumps = true,
        },
      })

      local move = require('nvim-treesitter-textobjects.move')
      vim.keymap.set({ 'n', 'x', 'o' }, ']m', function()
        move.goto_next_start('@function.outer', 'textobjects')
      end, { desc = 'Next function start (treesitter)' })
      vim.keymap.set({ 'n', 'x', 'o' }, '[m', function()
        move.goto_previous_start('@function.outer', 'textobjects')
      end, { desc = 'Previous function start (treesitter)' })
    end,
  },
}

