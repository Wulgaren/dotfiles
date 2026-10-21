local function extend(dst, src)
  for _, item in ipairs(src) do
    table.insert(dst, item)
  end
  return dst
end

local plugins = {}
extend(plugins, require('plugins.spec.telescope'))
extend(plugins, require('plugins.spec.treesitter'))
extend(plugins, require('plugins.spec.completion'))
extend(plugins, require('plugins.spec.editor'))
extend(plugins, require('plugins.spec.lsp'))
extend(plugins, require('plugins.spec.theme'))

return plugins
