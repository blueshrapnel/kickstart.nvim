return {
  {
    'lervag/vimtex',
    config = function()
      -- Set vimtex options
      vim.g.vimtex_view_method = 'zathura' -- Change this to your preferred PDF viewer
      vim.g.vimtex_compiler_method = 'latexmk'
    end,
  },
}
