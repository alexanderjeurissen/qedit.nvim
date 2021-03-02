local List = require("qedit/list")

local vim = vim or {}
local api = vim.api
local fn = vim.fn

local cmd = api.nvim_command

local module = {}
module.settings = { write = 1 }
module.state = {}

local function escape(str) return fn.escape(str, '\\/') end

function module.write()
  local bufnr = api.nvim_get_current_buf()
  local old_list = module.state[bufnr]
  _G.old_list = old_list

  -- Step 1. Persist modified tmpfile / list state
  cmd('silent! write!')
  old_list:refresh() -- reload list based on current list buffer
  local list = List:new()
  _G.list = list

  -- Step 2. Loop over list items and make substitutions
  list:first() -- go to first item in list

  local old_modeline = vim.o.modeline
  vim.o.modeline  = false -- prevents errors when entering large buffers

  local modifications = {}
  local count = 0

  for _, item in pairs(list.items) do
    -- Skip invalid list items
    if item.valid == 0 then list:next(); goto skip end

    local key, key_parts = List.generate_key(item) -- we need a key so we can quickly retrieve the old qf item
    local old_item = old_list.items[key]

    -- Skip items that did not exist in old qf list
    if not old_item then list:next(); goto skip end

    local before = vim.trim(old_item.text) -- trim so we don't replace whitespace
    local after = vim.trim(item.text) -- trim so we dont introduce new whitespace

    -- We dont want to substitute items that did not change
    if before == after then list:next(); goto skip end

    local substitute = item.lnum .. "snomagic/\\V" .. escape(before) .. '/' .. escape(after) .. '/'

    -- We dont want to substitute when we already made this substitution at the same file/line
    if modifications[key_parts[1] .. substitute] == true then list:next(); goto skip end

    cmd(substitute)

    modifications[key_parts[1] .. substitute] = true
    count = count + 1

    if module.settings.write == 1 then cmd('silent! write!') end
    list:next()

    ::skip::
  end

  vim.o.modeline = old_modeline
  cmd('echohl MoreMsg | echo "[QEDIT] Substituted ' .. count .. ' items" | echohl None')
end

function module.attach()
  assert(vim.bo.buftype == 'quickfix', 'Current buffer is not a quickfix window')

  local bufnr = api.nvim_get_current_buf()

  -- Don't attach to the same buffer twice
  if module.state[bufnr] then return end

  -- Step 1. Instantiate list
  local list = List:new({ idx = 3})

  if next(list.items) == nil then return end
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
