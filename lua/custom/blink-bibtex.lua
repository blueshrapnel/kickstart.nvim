-- blink.cmp source: citation keys from the .bib files in the nearest directory at or above
-- the file that has any (refs.bib, refs-workbench.bib, library.bib, ...), offered inside
-- \cite{...}, \citep[...]{a, b, ...}, \textcite{...} and friends.
--
-- Registered in lua/custom/plugins/blink-bibtex.lua as a fallback of the lsp source, so it
-- only fills in where texlab has no keys. That is the daily notes: master.tex \input's
-- them through computed paths in a \pgfcalendar loop, so texlab never links a note.tex to
-- master.tex's \addbibresource{refs.bib}. The same file uses source.keys() to drop texlab's
-- false "Undefined reference" on citations those .bib files do define.

local source = {}

local cache = {} -- .bib path -> { stamp = string, entries = { { key, title, author, year } } }

-- Contents of the {...} group opening at s[i], honouring nested braces.
local function braced(s, i)
  local depth, j = 0, i
  while true do
    j = s:find('[{}]', j)
    if not j then
      return nil
    end
    depth = depth + (s:sub(j, j) == '{' and 1 or -1)
    if depth == 0 then
      return s:sub(i + 1, j - 1)
    end
    j = j + 1
  end
end

-- Value of a bib field (braced, quoted or bare), with braces and whitespace runs removed.
local function field(body, name)
  local _, e = body:find('%f[%w]' .. name .. '%s*=%s*') -- %f[%w] so 'title' skips 'booktitle'
  if not e then
    return nil
  end
  local c = body:sub(e + 1, e + 1)
  local value = c == '{' and braced(body, e + 1) or c == '"' and body:match('^"([^"]*)"', e + 1) or body:match('^[^,%s}]+', e + 1)
  return value and vim.trim((value:gsub('[{}]', ''):gsub('%s+', ' ')))
end

local function parse(text)
  local entries, pos = {}, 1
  while true do
    local _, e, kind = text:find('@(%a+)%s*{', pos)
    if not e then
      break
    end
    local body = braced(text, e) or ''
    pos = e + #body + 1
    kind = kind:lower()
    local key = body:match '^%s*([^,%s]+)'
    if key and kind ~= 'string' and kind ~= 'comment' and kind ~= 'preamble' then
      table.insert(entries, { key = key, title = field(body, 'title'), author = field(body, 'author'), year = field(body, 'year') or field(body, 'date') })
    end
  end
  return entries
end

-- Entries of one .bib file, re-read only when the file changes.
local function load(path)
  local stat = vim.uv.fs_stat(path)
  if not stat then
    return {}
  end
  local stamp = stat.mtime.sec .. '.' .. stat.mtime.nsec .. '.' .. stat.size
  if not (cache[path] and cache[path].stamp == stamp) then
    local f = io.open(path, 'r')
    if not f then
      return {}
    end
    cache[path] = { stamp = stamp, entries = parse(f:read '*a') }
    f:close()
  end
  return cache[path].entries
end

-- .bib files in the nearest directory at or above the buffer's file that has any.
local function find_bibs(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == '' then
    return {}
  end
  for dir in vim.fs.parents(name) do
    local bibs = {}
    for file, type in vim.fs.dir(dir) do
      if type == 'file' and file:match '%.bib$' then
        table.insert(bibs, vim.fs.joinpath(dir, file))
      end
    end
    if #bibs > 0 then
      table.sort(bibs)
      return bibs
    end
  end
  return {}
end

-- Entries from all of the buffer's .bib files; a key found in several files is listed once.
local function entries(bufnr)
  local seen, list = {}, {}
  for _, path in ipairs(find_bibs(bufnr)) do
    for _, entry in ipairs(load(path)) do
      if not seen[entry.key] then
        seen[entry.key] = true
        table.insert(list, entry)
      end
    end
  end
  return list, seen
end

-- Set of citation keys available to the buffer: { [key] = true }.
function source.keys(bufnr)
  return select(2, entries(bufnr))
end

function source.new()
  return setmetatable({}, { __index = source })
end

-- '}' too: autopairs turns a typed '{' into '{}', so blink sees '}' as the trigger and only
-- shows the menu if a source declaring that character returned items.
function source:get_trigger_characters()
  return { '{', '}', ',' }
end

function source:get_completions(ctx, callback)
  local col = ctx.cursor[2]
  local before = ctx.line:sub(1, col)
  -- Inside an unclosed cite group: \<...>cite<...>[opt][opt]{keys so far
  if not before:match '\\%a*[Cc]ite%a*%*?[^{}]*{[^}]*$' then
    callback { items = {}, is_incomplete_forward = true, is_incomplete_backward = true }
    return
  end
  -- The key being typed starts after the last '{' or ','. blink's keyword (iskeyword) stops
  -- at '-', so pre-filter on everything typed up to the last '-' and let blink fuzzy-match the rest.
  local start = before:match '.*[{,]%s*()'
  local head = before:sub(start):match '^(.*%-)' or ''
  local row = ctx.cursor[1] - 1
  local range = { start = { line = row, character = start - 1 }, ['end'] = { line = row, character = col } }
  local items = {}
  for _, entry in ipairs((entries(ctx.bufnr))) do
    if entry.key:lower():find(head:lower(), 1, true) then
      local who = (entry.author or '?') .. (entry.year and (' (' .. entry.year .. ')') or '')
      table.insert(items, {
        label = entry.key,
        kind = require('blink.cmp.types').CompletionItemKind.Reference,
        textEdit = { newText = entry.key, range = range },
        documentation = { kind = 'markdown', value = '**' .. (entry.title or entry.key) .. '**\n\n' .. who },
      })
    end
  end
  callback { items = items, is_incomplete_forward = true, is_incomplete_backward = true }
end

return source
