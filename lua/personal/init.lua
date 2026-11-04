-- Personal extras: LaTeX (vimtex, texlab, daily notes, BibTeX citations) and julia.
-- init.lua requires this module only where ~/Dropbox/phd exists.
local M = {}

-- [[ LaTeX ]]
-- Daily notes hard-wrap at 120 columns (lua/personal/daily-notes.lua).
require('personal.daily-notes').setup()

vim.pack.add { 'https://github.com/lervag/vimtex' }
vim.g.vimtex_view_method = 'zathura'
vim.g.vimtex_compiler_method = 'latexmk'

-- Keep vimtex's regex syntax (math, \cite, sections, conceal) alongside Treesitter in LaTeX
-- buffers. Starting Treesitter highlighting turns 'syntax' off, and Kickstart starts it in its
-- own FileType autocmd, or once a newly installed parser is ready, so turn it back on after.
-- Kickstart installs the latex and bibtex parsers when a file of that type is first opened.
local function keep_tex_syntax(buf)
  if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].syntax ~= 'tex' then vim.bo[buf].syntax = 'tex' end
end
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'tex',
  callback = function(args)
    vim.schedule(function() keep_tex_syntax(args.buf) end)
    -- First use: the parser is still being installed; Treesitter starts when it is ready.
    vim.defer_fn(function() keep_tex_syntax(args.buf) end, 5000)
  end,
})

-- texlab is installed by hand (:MasonInstall texlab), not in the shared tool list.
-- It reports every \cite{key} it can't resolve as "Undefined reference" (code 11),
-- which is all of them when it can't link the file to its bibliography. Drop the ones
-- whose key is in the buffer's .bib files, so only genuinely unknown keys stay flagged.
vim.lsp.config('texlab', {
  handlers = {
    ['textDocument/publishDiagnostics'] = function(err, result, ctx)
      local bufnr = result and vim.uri_to_bufnr(result.uri)
      if bufnr and vim.api.nvim_buf_is_loaded(bufnr) then
        local encoding = vim.lsp.get_client_by_id(ctx.client_id).offset_encoding
        local keys
        result.diagnostics = vim.tbl_filter(function(d)
          local s, e = d.range.start, d.range['end']
          if tostring(d.code) ~= '11' or s.line ~= e.line then return true end
          keys = keys or require('personal.blink-bibtex').keys(bufnr)
          local line = vim.api.nvim_buf_get_lines(bufnr, s.line, s.line + 1, false)[1] or ''
          local from, to = vim.str_byteindex(line, encoding, s.character, false), vim.str_byteindex(line, encoding, e.character, false)
          return not keys[line:sub(from + 1, to)]
        end, result.diagnostics)
      end
      return vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx)
    end,
  },
})
if vim.fn.executable 'texlab' == 1 or vim.uv.fs_stat(vim.fn.stdpath 'data' .. '/mason/bin/texlab') then vim.lsp.enable 'texlab' end

-- Point texlab at a project's root file, e.g. :SetTexLabRootFile ~/Dropbox/phd/daily/master.tex
vim.api.nvim_create_user_command('SetTexLabRootFile', function(args)
  local client = vim.lsp.get_clients({ name = 'texlab' })[1]
  if not client then return vim.notify('TexLab is not running', vim.log.levels.WARN) end
  client:notify('workspace/didChangeConfiguration', { settings = { texlab = { rootFile = vim.fn.expand(args.args) } } })
  vim.notify('TexLab root file: ' .. args.args)
end, { nargs = 1, complete = 'file', desc = 'Set the TexLab root file' })

-- [[ Julia ]]
vim.pack.add { 'https://github.com/JuliaEditorSupport/julia-vim' }

-- [[ Completion ]]
-- Called by init.lua with blink.cmp's options before setup: citation keys in tex buffers
-- where texlab can't see the bibliography (e.g. the daily notes), from the nearest .bib
-- files (lua/personal/blink-bibtex.lua). Only used when texlab returns nothing, so projects
-- where texlab finds the .bib itself don't list every key twice.
function M.blink(opts)
  opts.sources.per_filetype = opts.sources.per_filetype or {}
  opts.sources.per_filetype.tex = { inherit_defaults = true, 'bibtex' }
  opts.sources.providers = opts.sources.providers or {}
  opts.sources.providers.bibtex = { name = 'BibTeX', module = 'personal.blink-bibtex' }
  opts.sources.providers.lsp = vim.tbl_deep_extend('force', opts.sources.providers.lsp or {}, { fallbacks = { 'buffer', 'bibtex' } })
end

return M
