local vim = vim or {}
local cmd = vim.api.nvim_command
local List = require('qedit/list')

local LocList = List:new({ type = 'loclist' })

function LocList:first() cmd('lfirst') end
function LocList:refresh() cmd('lgetbuf') end
function LocList:_list() return vim.fn.getloclist() end

function LocList:next(count, length)
  count = count or 1

  if length and self.idx >= length then goto reached_end end

  cmd(count .. 'lnext')
  self.idx = self.idx + count

  ::reached_end::
end

return LocList
