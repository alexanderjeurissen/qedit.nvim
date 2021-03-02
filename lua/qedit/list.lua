local vim = vim or {}
local api = vim.api
local fn = vim.fn

local List = {}
List.__index = List

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

function List:first()
  vim.cmd(self.prefix .. 'first')
  self.idx = 1
end

function List:refresh()
  vim.cmd(self.prefix .. 'getbuf')
  self.idx = 1
end

function List.get_items(prefix)
  if prefix == 'c' then return fn.getqflist() end
  if prefix == 'l' then return fn.getloclist() end

  return error('unknown list type')
end

function List:next()
  if next(self.items) == nil or self.idx >= self.item_count then
    return
  end

  vim.cmd(self.prefix .. 'next')
  self.idx = self.idx + 1
end

function List:new()
  local bufnr = api.nvim_get_current_buf()
  local list = {} -- list instance

  setmetatable(list, self) -- inherit List meta table

  -- Step 1. Set buffer/window info
  list.idx = 1
  list.winid = fn.win_getid()
  list.bufnr = bufnr
  list.tmpfile = fn.tempname() .. '.quickfix_edit'

  -- Step 2. Set prefix and items
  list.prefix = List.get_prefix()
  local items, count = List.parse_items(List.get_items(list.prefix))

  list.items = items
  list.item_count = count

  return list
end

return List
