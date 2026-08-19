return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    -- Not `ft = markdown`: first buffer can open before attach runs; VeryLazy is cheap.
    event = 'VeryLazy',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    opts = {},
  },
  { 'tpope/vim-fugitive' },
  {
    'echasnovski/mini.nvim',
    version = false,
    config = function()
      require('mini.surround').setup()
      require('mini.bracketed').setup({
        comment = { suffix = '' }, -- disabled (empty suffix = no maps; avoids stealing `[c`/`]c`)
      })

      -- `[e`/`]e`: errors only; `[d`/`]d` stay all severities (mini default).
      local err_opts = '{ severity = vim.diagnostic.severity.ERROR }'
      local err_maps = {
        { '[E', 'first', 'Error diagnostic first' },
        { '[e', 'backward', 'Error diagnostic backward' },
        { ']e', 'forward', 'Error diagnostic forward' },
        { ']E', 'last', 'Error diagnostic last' },
      }
      for _, m in ipairs(err_maps) do
        local cmd = ('<Cmd>lua MiniBracketed.diagnostic(%q, %s)<CR>'):format(m[2], err_opts)
        vim.keymap.set('n', m[1], cmd, { desc = m[3] })
        vim.keymap.set('x', m[1], cmd, { desc = m[3] })
        vim.keymap.set('o', m[1], 'v' .. cmd, { desc = m[3] })
      end
      require('mini.ai').setup()
      require('mini.comment').setup()
    end,
  }
}

