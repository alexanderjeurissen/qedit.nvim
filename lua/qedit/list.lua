local vim = vim or {}
local api = vim.api
local fn = vim.fn

local List = {}

List.generate_key = function(item)
  local parts = { fn.bufname(item.bufnr), item.lnum, item.col }
  return table.concat(parts, ':'), parts
end

List.get_prefix = function()
  local winid = fn.win_getid()
  local info = fn.getwininfo(winid)[1]

  if info['loclist'] == 1 then return 'l' end
  if info['quickfix'] == 1 then return 'c' end

  return error('win_id: ' .. winid .. ' has unknown list type')
end

List.parse_items = function(list)
  local items = {}
  local count = 0

  for _, item in ipairs(list) do
    items[List.generate_key(item)] = item
    count = count + 1
  end

  return items, count
end

function List:cmd(c) vim.cmd(self.prefix .. c) end
function List:first()
  List:cmd('first')
  self.idx = 1
end

function List:refresh()
  List:cmd('getbuf')
  self.idx = 1
end

function List:_items()
  if self.prefix == 'c' then return fn.getqflist() end
  if self.prefix == 'l' then return fn.getloclist() end

  return error('unknown list type')
end

function List:next()
  if next(self.items) == nil or self.idx >= self.item_count then
    return
  end

  List:cmd('next')

  self.idx = self.idx + 1
end

function List:new(opts)
  opts = opts or {}
  local bufnr = api.nvim_get_current_buf()

  -- Step 1. Set buffer/window info
  self.idx = 1
  self.winid = fn.win_getid()
  self.bufnr = bufnr
  self.tmpfile = fn.tempname() .. '.quickfix_edit'

  -- Step 2. Set prefix and items
  self.prefix = List.get_prefix()
  local items, count = List.parse_items(List:_items())

  self.items = items
  self.item_count = count

  -- Step 3. instantiate list
  setmetatable(opts, self)

  self.__index = self
  return opts
end

return List
