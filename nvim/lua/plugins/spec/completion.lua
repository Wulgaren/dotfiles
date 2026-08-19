return {
  {
    'saghen/blink.cmp',
    version = '*',
    opts = {
      keymap = {
        preset = 'none',
        --- Arrows: blink menu/snippet nav (was Tab / S-Tab). Tab reserved for NeoCodeium accept-word.
        ['<CR>'] = { 'accept', 'fallback' },
        ['<Down>'] = { 'select_next', 'snippet_forward', 'fallback' },
        ['<Up>'] = { 'select_prev', 'snippet_backward', 'fallback' },
        --- Toggle completion menu (<C-space> unreliable in many terminals).
        ['<C-e>'] = {
          function(cmp)
            if cmp.is_menu_visible() then
              return cmp.hide()
            end
            return cmp.show()
          end,
        },
      },
      appearance = {
        nerd_font_variant = 'mono',
      },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
        --- Show menu while typing in buffers. (NeoCodeium README sometimes uses `ctx.mode ~= 'default'`
        --- to hide blink until cmdline / manual open — that blocks popup in normal insert.)
        menu = {
          auto_show = true,
        },
      },
      sources = {
        default = { 'lsp', 'path', 'snippets' },
      },
      snippets = { preset = 'default' },
      fuzzy = { implementation = 'prefer_rust_with_warning' },
    },
  },
  {
    'monkoose/neocodeium',
    event = 'VeryLazy',
    dependencies = { 'saghen/blink.cmp' },
    --- No `filter` / no clear on `BlinkCmpMenuOpen`: NeoCodeium ghost text can show while blink menu open.
    --- Official README suggests hiding one when the other is up; if overlap annoys, try `single_line.enabled = true`.
    opts = {
      filetypes = {
        TelescopePrompt = false,
      },
    },
    config = function(_, opts)
      local neocodeium = require('neocodeium')
      neocodeium.setup(opts)
      vim.keymap.set('n', '<leader>ko', '<cmd>NeoCodeium toggle<CR>', {
        silent = true,
        desc = 'NeoCodeium toggle (no bang; use :NeoCodeium! toggle to halt server)',
      })
      --- Full suggestion accept (`accept`, not word). `<M-Tab>` = Alt+Tab; OS may capture it before Neovim.
      vim.keymap.set('i', '<M-Tab>', neocodeium.accept, { silent = true, desc = 'NeoCodeium: accept all' })
      vim.keymap.set('i', '<M-w>', neocodeium.accept_word, { silent = true, desc = 'NeoCodeium: accept word' })
      vim.keymap.set('i', '<M-l>', neocodeium.accept_line, { silent = true, desc = 'NeoCodeium: accept line' })
      vim.keymap.set('i', '<Tab>', function()
        if neocodeium.visible() then
          neocodeium.accept_word()
        else
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Tab>', true, false, true), 'n', true)
        end
      end, { silent = true, desc = 'NeoCodeium: accept word, else insert Tab' })
    end,
  },
}

