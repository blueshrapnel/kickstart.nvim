print 'loading custom mappings'
local M = {}
function M.setup()
  --vim.keymap.set('i', '<C-h>', '<C-o>:echo "Ctrl-h pressed"<CR>', { noremap = true, silent = false })
  vim.keymap.set('i', '<C-h>', '<BS>', { noremap = true, silent = true })
  -- more mappings here
end

return M
