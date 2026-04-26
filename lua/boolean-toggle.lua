local Util = require('boolean-toggle.util')
local Config = require('boolean-toggle.config')

local valid_chars = Util.dedup(vim.split('aeflrstuAEFLRSTU', '', { trimempty = false }))
local delim = vim.split([[.,'"()[]{}$#?!:;%%^%*@-_+=\\|/<>~ ]], '', { trimempty = false })

---@enum BooleanToggle.ConvertToFalse
local convert_to_false = {
  ['true'] = 'false',
  True = 'False',
  TRUE = 'FALSE',
}

---@enum BooleanToggle.ConvertToTrue
local convert_to_true = {
  ['false'] = 'true',
  False = 'True',
  FALSE = 'TRUE',
}

---@enum BooleanToggle.Convert
local convert = {
  ['true'] = 'false',
  ['false'] = 'true',
  True = 'False',
  False = 'True',
  TRUE = 'FALSE',
  FALSE = 'TRUE',
}

---@param line string
---@param col integer
---@return boolean valid
local function is_valid_char(line, col)
  Util.validate({
    line = { line, { 'string' } },
    col = { col, { 'number' } },
  })

  return vim.list_contains(valid_chars, line:sub(col, col))
end

---@param line string
---@param start_col integer
---@param end_col integer
---@return string before
---@return string after
local function get_boolean_surround(line, start_col, end_col)
  Util.validate({
    line = { line, { 'string' } },
    start_col = { start_col, { 'number' } },
    end_col = { start_col, { 'number' } },
  })

  return line:sub(1, start_col - 1), line:sub(end_col + 1, line:len())
end

---@class BooleanToggle
local M = {}

---@param opts? BooleanToggleOpts
function M.setup(opts)
  Util.validate({ opts = { opts, { 'table', 'nil' }, true } })

  Config.setup(opts or {})

  if Config.config.keymaps then
    if Config.config.keymaps.toggle and Config.config.keymaps.toggle ~= '' then
      vim.keymap.set(
        'n',
        Config.config.keymaps.toggle,
        M.cursor_toggle_boolean,
        { desc = 'Invert Boolean Value on Cursor' }
      )
    end
    if Config.config.keymaps.to_false and Config.config.keymaps.to_false ~= '' then
      vim.keymap.set(
        'n',
        Config.config.keymaps.to_false,
        M.cursor_set_to_false,
        { desc = 'Set Boolean on Cursor to `false`' }
      )
    end
    if Config.config.keymaps.to_true and Config.config.keymaps.to_true ~= '' then
      vim.keymap.set(
        'n',
        Config.config.keymaps.to_true,
        M.cursor_set_to_true,
        { desc = 'Set Boolean on Cursor to `true`' }
      )
    end
  end

  vim.api.nvim_create_user_command(
    'Bool',
    M.cursor_toggle_boolean,
    { desc = 'Invert Boolean Value on Cursor' }
  )
end

---@return boolean is_boolean
---@return integer|nil start_col
---@return integer|nil end_col
function M.boolean_under_cursor()
  local pos = vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win())
  local line = vim.api.nvim_get_current_line()
  local col = pos[2] + 1
  if not is_valid_char(line, col) then
    return false
  end
  while col > 0 do
    if vim.list_contains(delim, line:sub(col, col)) or col <= 0 then
      col = col + 1
      break
    end
    col = col - 1
  end

  local word, start_col = '', col
  while true do
    if vim.list_contains(delim, line:sub(col, col)) or col > line:len() then
      col = col - 1
      break
    end
    word = word .. line:sub(col, col)
    col = col + 1
  end

  if vim.list_contains({ 'false', 'true', 'False', 'True', 'FALSE', 'TRUE' }, word) then
    return true, start_col, col
  end
  return false
end

function M.cursor_toggle_boolean()
  local ok, start_col, end_col = M.boolean_under_cursor()
  if not (ok and start_col and end_col) then
    return
  end

  local line = vim.api.nvim_get_current_line()
  local current_bool = line:sub(start_col, end_col)
  if not convert[current_bool] then
    return
  end

  local win = vim.api.nvim_get_current_win()
  local pos = vim.api.nvim_win_get_cursor(win)
  local before, after = get_boolean_surround(line, start_col, end_col)
  if not vim.list_contains({ 'f', 'F', 't', 'T' }, line:sub(pos[2] + 1, pos[2] + 1)) then
    pos[2] = pos[2] + (line:len() > (before .. convert[current_bool] .. after):len() and -1 or 1)
  end

  vim.api.nvim_set_current_line(before .. convert[current_bool] .. after)
  pcall(vim.cmd.undojoin)
  vim.api.nvim_win_set_cursor(win, pos)

  if Config.config.auto_write then
    pcall(vim.cmd.write)
  end
end

function M.cursor_set_to_false()
  local ok, start_col, end_col = M.boolean_under_cursor()
  if not (ok and start_col and end_col) then
    return
  end

  local line = vim.api.nvim_get_current_line()
  local current_bool = line:sub(start_col, end_col)
  if not convert_to_false[current_bool] then
    return
  end

  local win = vim.api.nvim_get_current_win()
  local pos = vim.api.nvim_win_get_cursor(win)
  local before, after = get_boolean_surround(line, start_col, end_col)
  if not vim.list_contains({ 't', 'T' }, line:sub(pos[2] + 1, pos[2] + 1)) then
    pos[2] = pos[2]
      + (line:len() > (before .. convert_to_false[current_bool] .. after):len() and -1 or 1)
  end

  vim.api.nvim_set_current_line(before .. convert_to_false[line:sub(start_col, end_col)] .. after)
  pcall(vim.cmd.undojoin)
  vim.api.nvim_win_set_cursor(win, pos)

  if Config.config.auto_write then
    pcall(vim.cmd.write)
  end
end

function M.cursor_set_to_true()
  local ok, start_col, end_col = M.boolean_under_cursor()
  if not (ok and start_col and end_col) then
    return
  end

  local line = vim.api.nvim_get_current_line()
  local current_bool = line:sub(start_col, end_col)
  if not convert_to_true[current_bool] then
    return
  end

  local win = vim.api.nvim_get_current_win()
  local pos = vim.api.nvim_win_get_cursor(win)
  local before, after = get_boolean_surround(line, start_col, end_col)
  if not vim.list_contains({ 't', 'T' }, line:sub(pos[2] + 1, pos[2] + 1)) then
    pos[2] = pos[2]
      + (line:len() > (before .. convert_to_true[current_bool] .. after):len() and -1 or 1)
  end

  vim.api.nvim_set_current_line(before .. convert_to_true[line:sub(start_col, end_col)] .. after)
  pcall(vim.cmd.undojoin)
  vim.api.nvim_win_set_cursor(win, pos)

  if Config.config.auto_write then
    pcall(vim.cmd.write)
  end
end

function M.setup_keymaps() end

return M
-- vim: set ts=2 sts=2 sw=2 et ai si sta:
