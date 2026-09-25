-- Daily notes (~/Dropbox/phd/daily): hard-wrap at 120 columns while typing, in .tex files
-- anywhere below daily's subfolders (note.tex, minutes.tex, meeting-prep.tex, ...). The
-- files at the root of daily (master.tex, includes-*.tex) and everything else keep the
-- global no-wrap settings from init.lua.
--
-- Wrapping goes through a formatexpr rather than Vim's built-in auto-wrap, so a line is
-- never broken where LaTeX can't take a newline: inside \code{...} and the other
-- verbatim-style arguments, inside lstplain/lstlisting/verbatim blocks, or inside a
-- trailing % comment (the rest of the comment would become document text).

local M = {}

M.textwidth = 120

-- Any subfolder of daily, e.g. .../phd/daily/2026-September/2026-09-24/note.tex
local NOTE_PATH = '/phd/daily/[^/]+/'

-- Environments whose lines are never broken.
local VERBATIM_ENVS = {
  lstplain = true,
  lstlisting = true,
  lstpython = true,
  lstjulia = true,
  vrb = true,
  verbatim = true,
  Verbatim = true,
  minted = true,
  comment = true,
}

-- Commands whose first argument has to stay on one line.
local VERBATIM_ARGS = {
  code = true,
  lstinline = true,
  verb = true,
  Verb = true,
  url = true,
  path = true,
  href = true,
  urlref = true,
  fileref = true,
}

-- True when line lnum is inside one of VERBATIM_ENVS: the nearest \begin/\end above decides.
local function in_verbatim(lnum)
  for l = lnum, math.max(1, lnum - 5000), -1 do
    local last
    for kind, env in vim.fn.getline(l):gmatch '\\(%a+)%s*{(%a+)%*?}' do
      if (kind == 'begin' or kind == 'end') and VERBATIM_ENVS[env] then
        last = kind
      end
    end
    if last then
      return last == 'begin'
    end
  end
  return false
end

-- Index just past the argument starting at line[j]: an optional *, [options], then a
-- {braced} group or a |delimited| one (\verb|...|). An unclosed argument runs to the end.
local function skip_argument(line, j)
  j = line:match('^%*?%s*()', j)
  while line:sub(j, j) == '[' do
    local close = line:find(']', j, true)
    if not close then
      return #line + 1
    end
    j = close + 1
  end
  local open = line:sub(j, j)
  if open == '' then
    return j
  elseif open ~= '{' then
    local close = line:find(open, j + 1, true)
    return close and close + 1 or #line + 1
  end
  local depth = 0
  for k = j, #line do
    local c = line:sub(k, k)
    if c == '{' then
      depth = depth + 1
    elseif c == '}' then
      depth = depth - 1
      if depth == 0 then
        return k + 1
      end
    end
  end
  return #line + 1
end

-- Byte positions of the blanks where line may be broken: after the indent, before any
-- % comment, and outside the first argument of VERBATIM_ARGS and of citation commands
-- (\cite{a, b} stays on one line: the citation completion only reads the current line).
local function break_points(line)
  local points, i = {}, line:find '%S' or #line + 1
  while i <= #line do
    local c = line:sub(i, i)
    if c == '%' then
      break
    elseif c == '\\' then
      local name = line:match('^\\(%a+)', i)
      if name and (VERBATIM_ARGS[name] or name:lower():find('cite', 1, true)) then
        i = skip_argument(line, i + 1 + #name)
      else
        i = i + (name and #name + 1 or 2) -- a command name, or an escaped character such as \%
      end
    else
      if c == ' ' or c == '\t' then
        table.insert(points, i)
      end
      i = i + 1
    end
  end
  return points
end

-- The last break point whose preceding text fits in textwidth, else the first one past it.
local function choose_break(line, textwidth)
  local fits
  for _, b in ipairs(break_points(line)) do
    if vim.fn.strdisplaywidth(line:sub(1, b - 1)) <= textwidth then
      fits = b
    else
      return fits or b
    end
  end
  return fits
end

-- 'formatexpr' for the notes. While typing past textwidth it splits the line at a safe
-- blank and keeps the cursor on the same character. gq and other commands fall back to
-- Vim's built-in formatting: they call this with v:char empty (typing sets it to the key),
-- and gq calls it in insert state too, so mode() can't tell them apart.
function M.formatexpr()
  if vim.v.char == '' then
    return 1
  end
  local lnum = vim.v.lnum
  local line = vim.fn.getline(lnum)
  if line:match '^%s*%%' or in_verbatim(lnum) then
    return 0
  end
  local b = choose_break(line, vim.bo.textwidth)
  if not b then
    return 0
  end
  local indent = line:match '^%s*'
  local tail = line:find('%S', b) or #line + 1
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { (line:sub(1, b - 1):gsub('%s+$', '')), indent .. line:sub(tail) })
  if row == lnum and col >= b - 1 then
    vim.api.nvim_win_set_cursor(0, { lnum + 1, #indent + math.max(col - (tail - 1), 0) })
  else
    vim.api.nvim_win_set_cursor(0, { row, col })
  end
  return 0
end

function M.setup()
  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('daily-notes', { clear = true }),
    pattern = 'tex',
    callback = function(event)
      if not vim.api.nvim_buf_get_name(event.buf):match(NOTE_PATH) then
        return
      end
      local bo = vim.bo[event.buf]
      bo.textwidth = M.textwidth
      bo.formatoptions = bo.formatoptions:gsub('t', '') .. 't'
      bo.formatexpr = "v:lua.require'custom.daily-notes'.formatexpr()"
    end,
  })
end

return M
