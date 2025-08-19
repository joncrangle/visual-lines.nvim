vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
  group = vim.api.nvim_create_augroup('visual_lines', {}),
  callback = function()
    local ok, mod = pcall(require, 'visual-lines')
    if ok and not mod._initialized then
      vim.api.nvim_del_augroup_by_name 'visual_lines'
      mod.setup {}
    end
  end,
})
-- vim: ts=2 sts=2 sw=2 et
