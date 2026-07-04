local ERROR = vim.log.levels.ERROR
local Util = require('boolean-toggle.util')
local Config = require('boolean-toggle.config')

local delim = vim.split([[.,'"()[]{}$#?!:;%%^%*+=\\|/<>~` ]], '', { trimempty = false })

---@class BooleanToggle.ConvertSpec
---@field [1] string
---@field ft? string[]|nil

---@type table<string, BooleanToggle.ConvertSpec>
local convert_to_false = {
  ON = { 'OFF', ft = { '*' } },
  On = { 'Off', ft = { '*' } },
  TRUE = { 'FALSE', ft = { '*' } },
  True = { 'False', ft = { '*' } },
  YES = { 'NO', ft = { '*' } },
  Yes = { 'No', ft = { '*' } },
  ['nil'] = { 't', ft = { 'lisp' } },
  ['true'] = { 'false', ft = { '*' } },
  on = { 'off', ft = { '*' } },
  yes = { 'no', ft = { '*' } },
}

---@type table<string, BooleanToggle.ConvertSpec>
local convert_to_true = {
  FALSE = { 'TRUE', ft = { '*' } },
  False = { 'True', ft = { '*' } },
  NO = { 'NO', ft = { '*' } },
  No = { 'Yes', ft = { '*' } },
  OFF = { 'ON', ft = { '*' } },
  Off = { 'On', ft = { '*' } },
  ['false'] = { 'true', ft = { '*' } },
  no = { 'yes', ft = { '*' } },
  off = { 'on', ft = { '*' } },
  t = { 'nil', ft = { 'lisp' } },
}

---@type table<string, BooleanToggle.ConvertSpec>
local convert = {
  FALSE = { 'TRUE', ft = { '*' } },
  False = { 'True', ft = { '*' } },
  NO = { 'NO', ft = { '*' } },
  No = { 'Yes', ft = { '*' } },
  OFF = { 'ON', ft = { '*' } },
  ON = { 'OFF', ft = { '*' } },
  Off = { 'On', ft = { '*' } },
  On = { 'Off', ft = { '*' } },
  TRUE = { 'FALSE', ft = { '*' } },
  True = { 'False', ft = { '*' } },
  YES = { 'NO', ft = { '*' } },
  Yes = { 'No', ft = { '*' } },
  ['false'] = { 'true', ft = { '*' } },
  ['nil'] = { 't', ft = { 'lisp' } },
  ['true'] = { 'false', ft = { '*' } },
  no = { 'yes', ft = { '*' } },
  off = { 'on', ft = { '*' } },
  on = { 'off', ft = { '*' } },
  t = { 'nil', ft = { 'lisp' } },
  yes = { 'no', ft = { '*' } },
}

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
---@field config BooleanToggle.Config
---@field util BooleanToggle.Util
local M = {}

---@param ft? string
---@param bool? 'true'|'false'
---@return table<string, { [1]: string, ft: string[] }> values
function M.get_spec_values(ft, bool)
  Util.validate({
    ft = { ft, { 'string', 'nil' }, true },
    bool = { bool, { 'string', 'nil' }, true },
  })
  ft = ft or Util.optget('filetype', 'buf', vim.api.nvim_get_current_buf())
  if bool and not vim.list_contains({ 'true', 'false' }, bool) then
    error(('Invalid value `%s`'):format(bool), ERROR)
  end

  local conv = vim.deepcopy(not bool and convert or (bool == 'true' and convert_to_true or convert_to_false))
  if vim.tbl_isempty(Config.get().custom_spec) then
    return conv
  end

  for _, spec in ipairs(Config.get().custom_spec) do
    Util.validate({
      ['spec.yes'] = { spec.yes, { 'string' } },
      ['spec.no'] = { spec.no, { 'string' } },
      ['spec.ft'] = { spec.ft, { 'table', 'nil' }, true },
    })

    local ft_spec = (not spec.ft or vim.tbl_isempty(spec.ft)) and { '*' } or spec.ft
    if not bool then
      conv[spec.no] = { spec.yes, ft = ft_spec }
      conv[spec.yes] = { spec.no, ft = ft_spec }
    elseif bool == 'true' then
      conv[spec.no] = { spec.yes, ft = ft_spec }
    elseif bool == 'false' then
      conv[spec.yes] = { spec.no, ft = ft_spec }
    end
  end

  return conv
end

---@param opts? BooleanToggleOpts
function M.setup(opts)
  Util.validate({ opts = { opts, { 'table', 'nil' }, true } })

  Config.setup(opts or {})

  if Config.get().keymaps then
    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorHold' }, {
      group = vim.api.nvim_create_augroup('boolean_toggle', { clear = true }),
      callback = function(ev)
        if Config.get().keymaps.toggle and Config.get().keymaps.toggle ~= '' then
          if not M.boolean_under_cursor() then
            pcall(vim.keymap.del, 'n', Config.get().keymaps.toggle, { buf = ev.buf })
          else
            vim.keymap.set('n', Config.get().keymaps.toggle, M.cursor_toggle_boolean, {
              desc = 'Invert Boolean Value on Cursor',
              buf = ev.buf,
            })
          end
        end
        if Config.get().keymaps.to_false and Config.get().keymaps.to_false ~= '' then
          if not M.boolean_under_cursor('true') then
            pcall(vim.keymap.del, 'n', Config.get().keymaps.to_false, { buf = ev.buf })
          else
            vim.keymap.set('n', Config.get().keymaps.to_false, M.cursor_set_to_false, {
              desc = 'Set Boolean on Cursor to `false`',
              buf = ev.buf,
            })
          end
        end
        if Config.get().keymaps.to_true and Config.get().keymaps.to_true ~= '' then
          if not M.boolean_under_cursor('false') then
            pcall(vim.keymap.del, 'n', Config.get().keymaps.to_true, { buf = ev.buf })
          else
            vim.keymap.set('n', Config.get().keymaps.to_true, M.cursor_set_to_true, {
              desc = 'Set Boolean on Cursor to `true`',
              buf = ev.buf,
            })
          end
        end
      end,
    })
  end

  if Config.get().custom_spec and not vim.tbl_isempty(Config.get().custom_spec) then
    for _, spec in ipairs(Config.get().custom_spec) do
      if not (spec.yes and spec.no) then
        vim.notify(
          ('Spec is missing either its `yes` and/or `no` values\nyes: `%s`'):format(spec.yes or '', spec.no or ''),
          ERROR
        )
      end
    end
  end

  vim.api.nvim_create_user_command(
    'Bool',
    M.cursor_toggle_boolean,
    { desc = 'Invert Boolean Value on Cursor', nargs = 0 }
  )
end

---@param bool? 'true'|'false'
---@return boolean is_boolean
---@return integer|nil start_col
---@return integer|nil end_col
---@return table<string, { [1]: string, ft: string[] }>|nil convert
function M.boolean_under_cursor(bool)
  Util.validate({ bool = { bool, { 'string', 'nil' }, true } })
  if bool and not vim.list_contains({ 'true', 'false' }, bool) then
    error(('Invalid value `%s`'):format(bool), ERROR)
  end

  local pos = vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win())
  local line = vim.api.nvim_get_current_line()
  local col = pos[2] + 1
  if vim.list_contains(delim, line:sub(col, col)) then
    return false
  end

  while col > 0 do
    if vim.list_contains(delim, line:sub(col, col)) or col <= 0 then
      col = col + 1
      break
    end
    col = col - 1
  end

  local word, start_col = '', col ---@type string, integer
  while true do
    if vim.list_contains(delim, line:sub(col, col)) or col > line:len() then
      col = col - 1
      break
    end
    word = word .. line:sub(col, col)
    col = col + 1
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local ft = Util.optget('filetype', 'buf', bufnr) --[[@as string]]
  local conv
  if not bool then
    conv = M.get_spec_values('ft')
  elseif bool == 'true' then
    conv = M.get_spec_values('ft', 'true')
  elseif bool == 'false' then
    conv = M.get_spec_values('ft', 'false')
  end
  if not conv[word] then
    return false
  end

  local conv_ft = conv[word].ft or { '*' }
  if vim.list_contains(conv_ft, ft) or vim.tbl_isempty(conv_ft) or vim.list_contains(conv_ft, '*') then
    return true, start_col, col, conv
  end
  return false
end

---@return boolean success
function M.cursor_toggle_boolean()
  local bufnr = vim.api.nvim_get_current_buf()
  local ok, start_col, end_col, conv = M.boolean_under_cursor()
  if
    not (
      ok
      and start_col
      and end_col
      and conv
      and vim.list_contains({ 'acwrite', '' }, vim.api.nvim_get_option_value('buftype', { buf = bufnr }))
    ) or vim.list_contains(Config.get().ignore_ft, vim.api.nvim_get_option_value('filetype', { buf = bufnr }))
  then
    return false
  end

  local line = vim.api.nvim_get_current_line()
  local current_bool = line:sub(start_col, end_col)
  if not conv[current_bool] then
    return false
  end

  local win = vim.api.nvim_get_current_win()
  local pos = vim.api.nvim_win_get_cursor(win)
  local before, after = get_boolean_surround(line, start_col, end_col)

  vim.api.nvim_set_current_line(before .. conv[current_bool][1] .. after)
  local success = pcall(vim.cmd.undojoin)
  vim.api.nvim_win_set_cursor(win, pos)

  if Config.get().auto_write then
    success = pcall(vim.cmd.write)
  end
  return success
end

---@return boolean success
function M.cursor_set_to_false()
  local bufnr = vim.api.nvim_get_current_buf()
  local ok, start_col, end_col, conv = M.boolean_under_cursor('false')
  if
    not (
      ok
      and start_col
      and end_col
      and conv
      and vim.list_contains({ 'acwrite', '' }, vim.api.nvim_get_option_value('buftype', { buf = bufnr }))
    ) or vim.list_contains(Config.get().ignore_ft, vim.api.nvim_get_option_value('filetype', { buf = bufnr }))
  then
    return false
  end

  local line = vim.api.nvim_get_current_line()
  local current_bool = line:sub(start_col, end_col)
  if not conv[current_bool] then
    return false
  end

  local win = vim.api.nvim_get_current_win()
  local pos = vim.api.nvim_win_get_cursor(win)
  local before, after = get_boolean_surround(line, start_col, end_col)
  if not vim.list_contains({ 't', 'T' }, line:sub(pos[2] + 1, pos[2] + 1)) then
    pos[2] = pos[2] + (line:len() > (before .. conv[current_bool][1] .. after):len() and -1 or 1)
  end

  vim.api.nvim_set_current_line(before .. conv[line:sub(start_col, end_col)][1] .. after)
  local success = pcall(vim.cmd.undojoin)
  vim.api.nvim_win_set_cursor(win, pos)

  if Config.get().auto_write then
    success = pcall(vim.cmd.write)
  end
  return success
end

---@return boolean success
function M.cursor_set_to_true()
  local bufnr = vim.api.nvim_get_current_buf()
  local ok, start_col, end_col, conv = M.boolean_under_cursor('true')
  if
    not (
      ok
      and start_col
      and end_col
      and conv
      and vim.list_contains({ 'acwrite', '' }, vim.api.nvim_get_option_value('buftype', { buf = bufnr }))
    ) or vim.list_contains(Config.get().ignore_ft, vim.api.nvim_get_option_value('filetype', { buf = bufnr }))
  then
    return false
  end

  local line = vim.api.nvim_get_current_line()
  local current_bool = line:sub(start_col, end_col)
  if not conv[current_bool] then
    return false
  end

  local win = vim.api.nvim_get_current_win()
  local pos = vim.api.nvim_win_get_cursor(win)
  local before, after = get_boolean_surround(line, start_col, end_col)
  if not vim.list_contains({ 't', 'T', 'f', 'F', 'y', 'Y', 'n', 'N' }, line:sub(pos[2] + 1, pos[2] + 1)) then
    pos[2] = pos[2] + (line:len() > (before .. conv[current_bool][1] .. after):len() and -1 or 1)
  end

  vim.api.nvim_set_current_line(before .. conv[line:sub(start_col, end_col)][1] .. after)
  local success = pcall(vim.cmd.undojoin)
  vim.api.nvim_win_set_cursor(win, pos)

  if Config.get().auto_write then
    success = pcall(vim.cmd.write)
  end
  return success
end

local BooleanToggle = setmetatable(M, {
  __index = function(self, k)
    if Util.mod_exists('boolean-toggle.' .. k) then
      return require('boolean-toggle.' .. k)
    end
    return rawget(self, k) or nil
  end,
})

return BooleanToggle
-- vim: set ts=2 sts=2 sw=2 et ai si sta:
