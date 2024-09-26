-- https://github.com/chentoast/marks.nvim
return {
  'chentoast/marks.nvim',
  config = function()
    require('marks').setup {
      -- Default configurations; adjust as needed
      default_mappings = true, -- Whether to set default keybindings or not
      builtin_marks = { '.', '<', '>', '^' }, -- Builtin marks to support
      cyclic = true, -- When true, wrap around next/prev marks
      force_write_shada = false, -- Whether to write shada when setting marks
      refresh_interval = 250, -- Interval to refresh marks
      sign_priority = { lower = 10, upper = 15, builtin = 8, bookmark = 20 },
      excluded_filetypes = {}, -- Filetypes to disable marks for
      bookmark_0 = {
        sign = '⚑', -- Text for the sign
        virt_text = 'Bookmark', -- Text for the virtual text
      },
      mappings = {
        toggle = 'm.', -- Toggle mark
        delete_line = 'dm', -- Delete all marks on current line
        delete_buf = 'dm<space>', -- Delete all marks in current buffer
      },
    }
  end,
}
