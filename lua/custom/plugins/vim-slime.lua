-- https://github.com/jpalardy/vim-slime: send code to a REPL in another tmux pane
-- (C-c C-c), by default the top-right pane of the current tmux window.
vim.g.slime_target = 'tmux'
vim.g.slime_default_config = {
  socket_name = vim.split(vim.env.TMUX or '', ',')[1], -- first part of $TMUX
  target_pane = '{top-right}',
}
vim.pack.add { 'https://github.com/jpalardy/vim-slime' }
