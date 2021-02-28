local List = require("qedit/list")

--- NVIM INTERNAL SHORTCUTS {{{
local vim = vim or {}
local api = vim.api
local fn = vim.fn

local cmd = api.nvim_command
local inspect = vim.inspect
-- }}}

local module = {}

-- TODO: do we need this ?
module.settings = { write = 1 }

module.state = {}

local function escape(str) return fn.escape(str, '\\/') end

function module.write()
  local bufnr = api.nvim_get_current_buf()
  local list = module.state[bufnr]

  -- Step 1. Persist modified tmpfile / list state
  cmd('silent! write!')
  list.refresh() -- reload list based on current list buffer
  local new_list = list:_list() -- get the updated internal representation of the lits

  -- Step 2. Loop over list items and make substitutions
  list.first() -- go to first item in list
  list_count = #new_list

  local old_modeline = vim.o.modeline
  vim.o.modeline  = false -- prevents errors when entering large buffers

  for idx=1, list_count do
    local item = new_list[idx]

    -- Skip invalid list items
    if item.valid == 0 then list:next(1, list_count); goto skip end

    -- 1. trim so we don't replace whitespace
    -- 2. TODO: somehow vim does not render more then 180 lines in qf list
    -- 3. TODO: we need to replace the old qf description instead of the current line
    -- As the current line can be either to long or not represent the content rendered in the list
    local before = vim.trim(api.nvim_get_current_line()):sub(1, 180)
    local after = vim.trim(item.text) -- trim so we dont introduce new whitespace

    -- Skip items that did not change
    if before == after then list:next(1, list_count); goto skip end

    print('before')
    print(before)
    print('after')
    print(after)

    -- Make the substitution
    cmd(item.lnum .. "snomagic/\\V" .. escape(before) .. '/' .. escape(after) .. '/')

    if module.settings.write == 1 then cmd('silent! write!') end

    list:next(1, list_count)

    ::skip::
  end

  vim.o.modeline = old_modeline
  cmd('echohl MoreMsg | echo "Finished substituting ' .. list_count .. ' items" | echohl None')
end

function module.attach()
  assert(vim.bo.buftype == 'quickfix', 'Current buffer is not a quickfix window')

  local bufnr = api.nvim_get_current_buf()

  -- Don't attach to the same buffer twice
  if module.state[bufnr] then return end

  -- Step 1. Instantiate list
  local list = List.create_list()

  if #list:_list() == 0 then return end

  module.state[bufnr] = list

  -- Step 2. make buffer modifiable, and set error format
  vim.bo.modifiable = true
  vim.bo.swapfile = false
  vim.bo.errorformat = "%f|%l col %c|%m"

  -- Step 3. Write quickfix to temp file so `:w` and `:x` work
  cmd('silent! write! ' .. list.tmpfile)

  -- Step 4. Add a buffer update listener to detach
  api.nvim_buf_attach(bufnr, false, { on_detach = module.detach })
end

function module.detach()
  local bufnr = api.nvim_get_current_buf()
  local list = module.state[bufnr]

  -- Step 1. remove quickfix temp file
  os.remove(list.tmpfile)

  -- Step 2. remove buffer from qedit state
  module.state[bufnr] = nil
end

return module
-- vim: foldmethod=marker:sw=2:foldlevel=10
