local lspconfig = require 'lspconfig'
local util = require 'lspconfig.util'

vim.api.nvim_create_user_command('SetTexLabRootFile', function(args)
  -- Use the provided argument as the root file
  local root_file = args.args

  -- Check if the LSP client for TexLab is active
  local texlab_client = vim.lsp.get_active_clients({ name = 'texlab' })[1]
  if texlab_client then
    -- Notify TexLab of the new root file
    texlab_client.notify('workspace/didChangeConfiguration', {
      settings = {
        texlab = {
          rootFile = root_file,
        },
      },
    })
    print('TexLab root file set to: ' .. root_file)
  else
    print 'TexLab is not active or no client found.'
  end
end, {
  nargs = 1, -- Require exactly one argument
  desc = 'Set the TexLab root file dynamically (provide full file path)',
})

-- Return a valid table for lazy.nvim
return {}
