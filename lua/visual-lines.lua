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

---@type table<integer, integer>
local active_marks = {}

local last_buf = nil

-- Helpers ---------------------------------------------------------

local function get_fg()
  if options.fg then
    return options.fg
  end

  local hl = api.nvim_get_hl(0, {
    name = 'CursorLineNr',
    link = false,
  })

  return hl.fg or 'NONE'
end

local function set_hl()
  local ok, err = pcall(api.nvim_set_hl, 0, options.highlight_group, {
    fg = get_fg(),
    bg = options.bg,
  })

  if not ok then
    vim.notify('Error setting highlight group: ' .. tostring(err), vim.log.levels.ERROR)
  end
end

---@param bufnr integer
local function clear_marks(bufnr)
  if not api.nvim_buf_is_valid(bufnr) then
    active_marks = {}
    last_buf = nil
    return
  end

  api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  active_marks = {}
  last_buf = nil
end

---@param bufnr integer
---@param line integer
local function add_mark(bufnr, line)
  if active_marks[line] then
    return
  end

  local id = api.nvim_buf_set_extmark(bufnr, ns_id, line - 1, 0, {
    number_hl_group = options.highlight_group,
    priority = options.priority,
  })

  active_marks[line] = id
end

---@param bufnr integer
---@param line integer
local function del_mark(bufnr, line)
  local id = active_marks[line]

  if not id then
    return
  end

  pcall(api.nvim_buf_del_extmark, bufnr, ns_id, id)
  active_marks[line] = nil
end

---@param bufnr integer
---@return boolean
local function is_excluded(bufnr)
  local bo = vim.bo[bufnr]

  return options.exclude_filetypes[bo.filetype] == true or options.exclude_buftypes[bo.buftype] == true
end

---@return boolean
local function is_visual_mode()
  local mode = api.nvim_get_mode().mode
  return mode == 'v' or mode == 'V' or mode == '\x16'
end

---@return integer, integer
local function get_visual_range()
  local start_line = vim.fn.line 'v'
  local end_line = vim.fn.line '.'

  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  return start_line, end_line
end

-- Core ------------------------------------------------------------

local function update_highlights()
  if not is_enabled then
    return
  end

  local bufnr = api.nvim_get_current_buf()

  if is_excluded(bufnr) then
    if last_buf then
      clear_marks(last_buf)
    end
    return
  end

  if not is_visual_mode() then
    if last_buf then
      clear_marks(last_buf)
    end
    return
  end

  local start_line, end_line = get_visual_range()
  local line_count = end_line - start_line + 1

  if line_count > options.max_lines then
    if last_buf then
      clear_marks(last_buf)
    end
    return
  end

  -- Selection moved to another buffer.
  if last_buf and last_buf ~= bufnr then
    clear_marks(last_buf)
  end

  -- Remove only marks that are no longer part of the selection.
  --
  -- Iterating active_marks instead of the previous numeric range keeps the
  -- bookkeeping tied to what we actually believe is currently decorated.
  local marks_to_remove = {}

  for line in pairs(active_marks) do
    if line < start_line or line > end_line then
      marks_to_remove[#marks_to_remove + 1] = line
    end
  end

  for _, line in ipairs(marks_to_remove) do
    del_mark(bufnr, line)
  end

  -- Ensure every selected line has a mark.
  --
  -- Existing lines incur only a table lookup; extmarks are created only for
  -- lines that have newly entered the selection.
  for line = start_line, end_line do
    if not active_marks[line] then
      add_mark(bufnr, line)
    end
  end

  last_buf = bufnr
end

-- Public API ------------------------------------------------------

function M.enable()
  if is_enabled then
    return
  end

  is_enabled = true
  update_highlights()
end

function M.disable()
  if not is_enabled then
    return
  end

  is_enabled = false

  if last_buf then
    clear_marks(last_buf)
  end
end

function M.toggle()
  if is_enabled then
    M.disable()
  else
    M.enable()
  end
end

---@param arg string
function M.command(arg)
  if arg == 'enable' then
    M.enable()
  elseif arg == 'disable' then
    M.disable()
  elseif arg == 'toggle' then
    M.toggle()
  else
    vim.notify('Invalid argument for VisualLineNumbers: ' .. tostring(arg), vim.log.levels.ERROR)
  end
end

---@param opts? VisualLineNumbersOptions
function M.setup(opts)
  if M._initialized then
    return
  end

  M._initialized = true

  options = vim.tbl_deep_extend('force', defaults, opts or {})
  options.exclude_filetypes = options.exclude_filetypes or {}
  options.exclude_buftypes = options.exclude_buftypes or {}

  set_hl()

  local group = api.nvim_create_augroup('VisualLineNumbers', {
    clear = true,
  })

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
      if last_buf == args.buf then
        clear_marks(args.buf)
      else
        api.nvim_buf_clear_namespace(args.buf, ns_id, 0, -1)
      end
    end,
  })

  update_highlights()
end

return M
-- vim: ts=2 sts=2 sw=2 et
