local lspconfig = require 'lspconfig'
local util = require 'lspconfig.util'

-- Function to load project-specific settings.json
local function load_texlab_settings()
  local root_dir = util.root_pattern('settings.json', 'master.tex', '.git')(vim.fn.expand '%:p')
  if not root_dir then
    return {}
  end

  local settings_file = root_dir .. '/settings.json'
  if vim.fn.filereadable(settings_file) == 1 then
    local settings = vim.fn.json_decode(vim.fn.readfile(settings_file))
    if settings and settings.texlab and settings.texlab.rootFile then
      return settings.texlab.rootFile
    end
  end
  return nil
end

-- Dynamically set texlab rootFile
vim.api.nvim_create_user_command('SetTexLabRootFile', function()
  local current_file = vim.fn.expand '%:p'
  local root_file = load_texlab_settings() or vim.fn.fnamemodify(current_file, ':p:h:h') .. '/master.tex'

  for _, client in pairs(vim.lsp.get_active_clients()) do
    if client.name == 'texlab' then
      client.notify('workspace/didChangeConfiguration', {
        settings = {
          texlab = {
            rootFile = root_file,
          },
        },
      })
      print('TexLab root file set to: ' .. root_file)
    end
  end
end, {})

-- Return a valid table for lazy.nvim
return {}
