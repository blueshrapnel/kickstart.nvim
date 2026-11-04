-- https://github.com/jiangmiao/auto-pairs
-- Its options are read when the plugin loads, so set them before vim.pack.add.
vim.g.AutoPairsFlyMode = 1
vim.g.AutoPairsShortcutToggle = '<C-]>'
vim.g.AutoPairsShortcutFastWrap = '<C-e>'
vim.g.AutoPairsShortcutJump = '<C-i>'
vim.g.AutoPairsShortcutBackInsert = '<C-q>'
vim.pack.add { 'https://github.com/jiangmiao/auto-pairs' }
