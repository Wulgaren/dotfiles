local ok, catppuccin = pcall(require, 'catppuccin')
if not ok then
  vim.cmd('colorscheme default')
  return
end

catppuccin.setup({
  transparent_background = true,
})

local function apply_readability_overrides(is_light)
  local fg = is_light and '#3f455e' or '#e8ecff'
  -- Softer foreground for non-current windows (splits feel less “loud”).
  local fg_nc = is_light and '#7a8199' or '#a7b0cc'
  local line_nr = is_light and '#525a76' or '#cfd5f2'
  -- Comments: don’t reuse line_nr in dark (too bright); use Frappe overlay0-ish gray.
  local comment_fg = is_light and line_nr or '#737994'
  local border = is_light and '#59627f' or '#d7defc'

  -- Light + frappe: Catppuccin CursorLine is dark; use soft stripe so Normal fg stays readable.
  local cursorline_bg = is_light and '#e9ecf6' or '#3b3f52'

  local groups = {
    Normal = { fg = fg, bg = 'NONE' },
    NormalNC = { fg = fg_nc, bg = 'NONE' },
    NormalFloat = { fg = fg, bg = 'NONE' },
    SignColumn = { bg = 'NONE' },
    EndOfBuffer = { fg = line_nr, bg = 'NONE' },
    LineNr = { fg = line_nr, bg = 'NONE' },
    CursorLine = {  bg = cursorline_bg, bold = true },
    FloatBorder = { fg = border, bg = 'NONE' },
    WinSeparator = { fg = border, bg = 'NONE' },
    Comment = { fg = comment_fg, italic = true },
    NonText = { fg = line_nr },
    Whitespace = { fg = line_nr },
  }

  for group, spec in pairs(groups) do
    vim.api.nvim_set_hl(0, group, spec)
  end
end

local function set_catppuccin_light()
  vim.o.background = 'light'
  vim.g.catppuccin_flavour = 'frappe'
  vim.cmd('colorscheme catppuccin')
  apply_readability_overrides(true)
end

local function set_catppuccin_dark()
  vim.o.background = 'dark'
  vim.g.catppuccin_flavour = 'frappe'
  vim.cmd('colorscheme catppuccin')
  apply_readability_overrides(false)
end

vim.api.nvim_create_user_command('CatppuccinLight', set_catppuccin_light, {})
vim.api.nvim_create_user_command('CatppuccinDark', set_catppuccin_dark, {})

if vim.o.background == 'light' then
  set_catppuccin_light()
else
  set_catppuccin_dark()
end
