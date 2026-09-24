-- Citations for tex buffers where texlab can't see the bibliography (e.g. the daily notes),
-- using the nearest .bib files (source: lua/custom/blink-bibtex.lua).
return {
  {
    'saghen/blink.cmp',
    opts = function(_, opts)
      opts.sources.per_filetype = opts.sources.per_filetype or {}
      opts.sources.per_filetype.tex = { inherit_defaults = true, 'bibtex' }
      opts.sources.providers.bibtex = { name = 'BibTeX', module = 'custom.blink-bibtex' }
      -- Only used when texlab returns nothing, so projects where texlab finds the .bib
      -- itself don't list every key twice. ('buffer' is blink's default lsp fallback.)
      opts.sources.providers.lsp = vim.tbl_deep_extend('force', opts.sources.providers.lsp or {}, { fallbacks = { 'buffer', 'bibtex' } })
      return opts
    end,
  },
  {
    'neovim/nvim-lspconfig',
    init = function()
      -- texlab reports every \cite{key} it can't resolve as "Undefined reference" (code 11),
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
                if tostring(d.code) ~= '11' or s.line ~= e.line then
                  return true
                end
                keys = keys or require('custom.blink-bibtex').keys(bufnr)
                local line = vim.api.nvim_buf_get_lines(bufnr, s.line, s.line + 1, false)[1] or ''
                local from, to = vim.str_byteindex(line, encoding, s.character, false), vim.str_byteindex(line, encoding, e.character, false)
                return not keys[line:sub(from + 1, to)]
              end, result.diagnostics)
            end
            return vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx)
          end,
        },
      })
    end,
  },
}
