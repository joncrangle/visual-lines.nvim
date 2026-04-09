local loaded = false

local function load()
  if loaded then
    return
  end
  loaded = true

  local ok, mod = pcall(require, 'visual-lines')
  if not ok then
    return
  end

  mod.setup {}
end

vim.api.nvim_create_autocmd('ModeChanged', {
  pattern = '*:[vV\x16]*',
  once = true,
  callback = load,
})

-- Create user commands
vim.api.nvim_create_user_command('VisualLineNumbers', function(opts)
  load()
  require('visual-lines').command(opts.args)
end, {
  nargs = 1,
  complete = function()
    return { 'enable', 'disable', 'toggle' }
  end,
  desc = 'Control visual-lines.lua plugin (enable/disable/toggle)',
})
-- vim: ts=2 sts=2 sw=2 et
