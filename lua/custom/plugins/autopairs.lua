-- ~/.config/nvim/lua/custom/plugins/auto-pairs.lua
return {
  'jiangmiao/auto-pairs',
  config = function()
    -- setting fly mode on by default
    vim.g.AutoPairsFlyMode = 1

    -- Customize the keybindings for auto-pairs
    vim.g.AutoPairsShortcutToggle = '<C-]>'
    vim.g.AutoPairsShortcutFastWrap = '<C-e>'
    vim.g.AutoPairsShortcutJump = '<C-i>'
    vim.g.AutoPairsShortcutBackInsert = '<C-q>'
  end,
}
