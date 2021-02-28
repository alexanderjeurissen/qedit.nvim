local vim = vim or {}
local api = vim.api
local fn = vim.fn

local tbl_map = vim.tbl_map

local List = {}

List.read_lines = function(bufnr)
  return api.nvim_buf_get_lines(bufnr or 0, 0, -1, true)
end

List.parse_item = function(line)
  local filename, lnum, col, text = string.match(line, '(.*)|(%d+) col (%d+)|%s(.*)')
  local key = filename .. ':' .. lnum .. ':' .. col

  return key, { filename = filename, lnum = lnum, col = col, text = text }
end

List.parse_items = function(lines)
  if #lines == 1 and lines[1] == '' then return {} end

  local items = {}

  for _, line in ipairs(lines) do
    local key, value = List.parse_item(line)
    items[key] = value
  end

  return items
end

List.create_list = function(opts)
  local winid = fn.win_getid()
  local info = fn.getwininfo(winid)[1]

  if info['loclist'] == 1 then
    return require('qedit/location_list'):new(opts)
  end

  if info['quickfix'] == 1 then
    return require('qedit/quickfix_list'):new(opts)
  end

  return error('win_id: ' .. winid .. ' has unknown list type')
end

function List:new(opts)
  local bufnr = api.nvim_get_current_buf()

  -- Step 1. instantiate list defaults
  local defaults = {}
  defaults.winid = fn.win_getid()
  defaults.bufnr = bufnr
  defaults.tmpfile = fn.tempname() .. '.quickfix_edit'
  defaults.lines = List.read_lines(bufnr)
  defaults.items = List.parse_items(defaults.lines)
  defaults.idx = 1

  -- Step 2. merge defaults with user provided options
  opts = opts or {}
  opts = vim.tbl_extend('force', defaults, opts)

  -- Step 3. instantiate list
  setmetatable(opts, self)

  self.__index = self
  return opts
end

return List
