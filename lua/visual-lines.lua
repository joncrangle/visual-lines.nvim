---@class VisualLineNumbersOptions
---@field fg? string Foreground color (defaults to CursorLineNr fg at init time)
---@field bg? string Background color (default: 'NONE')
---@field highlight_group? string Highlight group name (default: 'VisualLineNr')
---@field max_lines? number Maximum number of lines to highlight (default: 2000)
---@field priority? number Extmark priority (default: 10)
---@field exclude_filetypes? table<string, boolean> Dictionary of filetypes to exclude
---@field exclude_buftypes? table<string, boolean> Dictionary of buftypes to exclude
local M = {}

local api = vim.api

M._initialized = false
local is_enabled = true

local defaults = {
  bg = 'NONE',
  highlight_group = 'VisualLineNr',
  max_lines = 2000,
  priority = 10,
  exclude_filetypes = {
    alpha = true,
    checkhealth = true,
    dashboard = true,
    help = true,
    lazy = true,
    lazygit = true,
    lspinfo = true,
    man = true,
    mason = true,
    minifiles = true,
    ministarter = true,
    ['neo-tree'] = true,
    noice = true,
    notify = true,
    NvimTree = true,
    qf = true,
    snacks_dashboard = true,
    snacks_picker_input = true,
    snacks_picker_list = true,
    snacks_terminal = true,
    TelescopePrompt = true,
    TelescopeResults = true,
    Trouble = true,
  },
  exclude_buftypes = {
    nofile = true,
    prompt = true,
    quickfix = true,
    terminal = true,
  },
}

local options = {}
local ns_id = api.nvim_create_namespace 'visual_line_numbers'

-- Track extmarks per line
local active_marks = {} ---@type table<integer, integer>

-- State cache
local last_start = nil
local last_end = nil
local last_buf = nil

-- Helpers ---------------------------------------------------------

local function get_fg()
  if options.fg then
    return options.fg
  end
  local hl = api.nvim_get_hl(0, { name = 'CursorLineNr', link = false })
  return hl.fg or 'NONE'
end

local function set_hl()
  local ok, err = pcall(function()
    api.nvim_set_hl(0, options.highlight_group, {
      fg = get_fg(),
      bg = options.bg,
    })
  end)

  if not ok then
    vim.notify('Error setting highlight group: ' .. tostring(err), vim.log.levels.ERROR)
  end
end

local function clear_marks(bufnr)
  bufnr = bufnr or 0
  api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  active_marks = {}
  last_start, last_end, last_buf = nil, nil, nil
end

local function add_mark(bufnr, line)
  local id = api.nvim_buf_set_extmark(bufnr, ns_id, line - 1, 0, {
    number_hl_group = options.highlight_group,
    priority = options.priority,
  })
  active_marks[line] = id
end

local function del_mark(bufnr, line)
  local id = active_marks[line]
  if id then
    pcall(api.nvim_buf_del_extmark, bufnr, ns_id, id)
    active_marks[line] = nil
  end
end

local function is_excluded(bufnr)
  local bo = vim.bo[bufnr]
  return options.exclude_filetypes[bo.filetype] or options.exclude_buftypes[bo.buftype]
end

-- Core ------------------------------------------------------------

local function update_highlights()
  if not is_enabled then
    return
  end

  local bufnr = api.nvim_get_current_buf()

  -- Handle excluded buffers (clear previous)
  if is_excluded(bufnr) then
    if last_buf then
      clear_marks(last_buf)
    end
    return
  end

  local current_mode = api.nvim_get_mode().mode

  -- Exit visual mode → clear
  if not current_mode:match '[vV\x16]' then
    if last_buf then
      clear_marks(last_buf)
    end
    return
  end

  local start_line = vim.fn.line 'v'
  local end_line = vim.fn.line '.'

  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  -- Cap large selections
  if (end_line - start_line) > options.max_lines then
    if last_buf then
      clear_marks(last_buf)
    end
    return
  end

  -- Buffer changed → full reset
  if last_buf and bufnr ~= last_buf then
    clear_marks(last_buf)
  end

  -- First run → populate
  if not last_start or not last_end then
    for line = start_line, end_line do
      add_mark(bufnr, line)
    end
  else
    -- Remove lines no longer in range
    for line = last_start, last_end do
      if line < start_line or line > end_line then
        del_mark(bufnr, line)
      end
    end

    -- Add new lines
    for line = start_line, end_line do
      if not active_marks[line] then
        add_mark(bufnr, line)
      end
    end
  end

  -- Cache state
  last_start = start_line
  last_end = end_line
  last_buf = bufnr
end

-- Public API ------------------------------------------------------

function M.enable()
  is_enabled = true
  update_highlights()
end

function M.disable()
  is_enabled = false
  if last_buf then
    clear_marks(last_buf)
  end
  clear_marks(api.nvim_get_current_buf())
end

function M.toggle()
  if is_enabled then
    M.disable()
  else
    M.enable()
  end
end

function M.command(arg)
  if arg == 'enable' then
    M.enable()
  elseif arg == 'disable' then
    M.disable()
  elseif arg == 'toggle' then
    M.toggle()
  else
    vim.notify('Invalid argument for VisualLineNumbers', vim.log.levels.ERROR)
  end
end

---@param opts VisualLineNumbersOptions|{}
M.setup = function(opts)
  if M._initialized then
    return
  end
  M._initialized = true

  options = vim.tbl_deep_extend('force', defaults, opts or {})
  options.exclude_filetypes = options.exclude_filetypes or {}
  options.exclude_buftypes = options.exclude_buftypes or {}

  set_hl()

  local group = api.nvim_create_augroup('VisualLineNumbers', { clear = true })

  api.nvim_create_autocmd('ColorScheme', {
    group = group,
    callback = set_hl,
  })

  api.nvim_create_autocmd({ 'CursorMoved', 'ModeChanged' }, {
    group = group,
    callback = update_highlights,
  })

  api.nvim_create_autocmd('BufLeave', {
    group = group,
    callback = function(args)
      clear_marks(args.buf)
    end,
  })

  update_highlights()
end

return M
-- vim: ts=2 sts=2 sw=2 et
