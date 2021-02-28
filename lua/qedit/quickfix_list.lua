local vim = vim or {}
local cmd = vim.api.nvim_command
local List = require('qedit/list')

local QfList = List:new({ type = 'quickfix' })

function QfList:first() cmd('cfirst') end
function QfList:refresh() cmd('cgetbuf') end
function QfList:_list() return vim.fn.getqflist() end

function QfList:next(count, length)
  count = count or 1

  if length and self.idx >= length then goto reached_end end

  cmd(count .. 'cnext')
  self.idx = self.idx + count

  ::reached_end::
end

return QfList
