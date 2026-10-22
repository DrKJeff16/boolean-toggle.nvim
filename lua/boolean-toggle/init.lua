---@module 'boolean-toggle._meta'

local delim = vim.split([[.,'"()[]{}$#?!:;%%^%*+=\\|/<>~` ]], '', { trimempty = false })
local excluded_bt = { 'help', 'nofile', 'nowrite', 'quickfix', 'terminal' } ---@type string[]
local excluded_ft = { ---@type string[]
  'NvimTree',
  'TelescopePrompt',
  'TelescopeResults',
  'fzf',
  'lazy',
  'neo-tree',
  'qf',
  'snacks_picker_input',
}

---@generic T: table, F
---@param t T
---@param k any
---@param fallback F
---@return F fallback
local function get(t, k, fallback)
  local Util = require('boolean-toggle.util')
  return Util.get(t, k, function()
    return Util.rawset(t, k, fallback)
  end, true)
end

---@class BooleanToggle.ConvertSpec
---@field [1] string
---@field ft? string[]

local convert_to_false = { ---@type table<string, BooleanToggle.ConvertSpec>
  ALWAYS = { 'NEVER', ft = { '*' } },
  Always = { 'Never', ft = { '*' } },
  ENABLE = { 'DISABLE', ft = { '*' } },
  ENABLED = { 'DISABLED', ft = { '*' } },
  Enable = { 'Disable', ft = { '*' } },
  Enabled = { 'Disabled', ft = { '*' } },
  ON = { 'OFF', ft = { '*' } },
  On = { 'Off', ft = { '*' } },
  TRUE = { 'FALSE', ft = { '*' } },
  True = { 'False', ft = { '*' } },
  YES = { 'NO', ft = { '*' } },
  Yes = { 'No', ft = { '*' } },
  ['true'] = { 'false', ft = { '*' } },
  always = { 'never', ft = { '*' } },
  enable = { 'disable', ft = { '*' } },
  enabled = { 'disabled', ft = { '*' } },
  on = { 'off', ft = { '*' } },
  t = { 'nil', ft = { 'lisp' } },
  yes = { 'no', ft = { '*' } },
}

local convert_to_true = { ---@type table<string, BooleanToggle.ConvertSpec>
  DISABLE = { 'ENABLE', ft = { '*' } },
  DISABLED = { 'ENABLED', ft = { '*' } },
  Disable = { 'Enable', ft = { '*' } },
  Disabled = { 'Enabled', ft = { '*' } },
  FALSE = { 'TRUE', ft = { '*' } },
  False = { 'True', ft = { '*' } },
  NEVER = { 'ALWAYS', ft = { '*' } },
  NO = { 'YES', ft = { '*' } },
  Never = { 'Always', ft = { '*' } },
  No = { 'Yes', ft = { '*' } },
  OFF = { 'ON', ft = { '*' } },
  Off = { 'On', ft = { '*' } },
  ['false'] = { 'true', ft = { '*' } },
  ['nil'] = { 't', ft = { 'lisp' } },
  disable = { 'enable', ft = { '*' } },
  disabled = { 'enabled', ft = { '*' } },
  never = { 'always', ft = { '*' } },
  no = { 'yes', ft = { '*' } },
  off = { 'on', ft = { '*' } },
}

local convert = vim.tbl_deep_extend('force', convert_to_true, convert_to_false) ---@type table<string, BooleanToggle.ConvertSpec>

---@param line string
---@param start_col integer
---@param end_col integer
---@return string before
---@return string after
---@nodiscard
local function get_boolean_surround(line, start_col, end_col)
  require('boolean-toggle.util').validate({
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

setmetatable(M, {
  __index = function(self, k) ---@param self BooleanToggle
    local Util = require('boolean-toggle.util')
    local raw = Util.get(self, k)
    if raw ~= nil then
      return raw
    end

    if type(k) ~= 'string' then
      return
    end

    ---@cast k string
    if Util.mod_exists('boolean-toggle.' .. k) then
      return get(self, k, require('boolean-toggle.' .. k))
    end
  end,
})

---@param ft? string
---@param bool? 'true'|'false'
---@return table<string, { [1]: string, ft: string[] }> values
function M.get_spec_values(ft, bool)
  M.util.validate({
    ft = { ft, { 'string', 'nil' }, true },
    bool = { bool, { 'string', 'nil' }, true },
  })
  ft = ft or M.util.optget('filetype', 'buf', vim.api.nvim_get_current_buf())
  if bool and not vim.list_contains({ 'true', 'false' }, bool) then
    error(('Invalid value `%s`'):format(bool))
  end

  local conv = vim.deepcopy(not bool and convert or (bool == 'true' and convert_to_true or convert_to_false))
  for _, spec in ipairs(M.config.get().custom_spec) do
    M.util.validate({
      ['spec.yes'] = { spec.yes, { 'string' } },
      ['spec.no'] = { spec.no, { 'string' } },
      ['spec.ft'] = { spec.ft, { 'table', 'nil' }, true },
    })

    local ft_spec = (not spec.ft or #spec.ft == 0) and { '*' } or spec.ft
    if not bool then
      conv[spec.no], conv[spec.yes] = { spec.yes, ft = ft_spec }, { spec.no, ft = ft_spec }
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
  M.util.validate({ opts = { opts, { 'table', 'nil' }, true } })

  M.config.setup(opts or {})

  local config = M.config.get()
  if config.keymaps then
    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorHold' }, {
      group = vim.api.nvim_create_augroup('boolean_toggle', { clear = true }),
      callback = function(ev)
        if
          vim.list_contains(excluded_ft, M.util.optget('filetype', 'buf', ev.buf))
          or vim.list_contains(excluded_bt, M.util.optget('buftype', 'buf', ev.buf))
        then
          return
        end

        local under_cursor ---@type boolean
        if config.keymaps.toggle and config.keymaps.toggle ~= '' then
          under_cursor = M.boolean_under_cursor()
          if not under_cursor and vim.g.boolean_toggle_toggle_keymap == 1 then
            pcall(vim.keymap.del, 'n', config.keymaps.toggle, { buf = ev.buf })
            vim.g.boolean_toggle_toggle_keymap = 0
          elseif under_cursor then
            vim.keymap.set(
              'n',
              config.keymaps.toggle,
              M.cursor_toggle_boolean,
              { desc = 'Invert Boolean Value on Cursor', buf = ev.buf }
            )
            vim.g.boolean_toggle_toggle_keymap = 1
          end
        end
        if config.keymaps.to_false and config.keymaps.to_false ~= '' then
          under_cursor = M.boolean_under_cursor('true')
          if not under_cursor and vim.g.boolean_toggle_to_false_keymap == 1 then
            pcall(vim.keymap.del, 'n', config.keymaps.to_false, { buf = ev.buf })
            vim.g.boolean_toggle_to_false_keymap = 0
          elseif under_cursor then
            vim.keymap.set(
              'n',
              config.keymaps.to_false,
              M.cursor_set_to_false,
              { buf = ev.buf, desc = 'Set Boolean on Cursor to `false`' }
            )
            vim.g.boolean_toggle_to_false_keymap = 1
          end
        end
        if config.keymaps.to_true and config.keymaps.to_true ~= '' then
          under_cursor = M.boolean_under_cursor('false')
          if not under_cursor and vim.g.boolean_toggle_to_true_keymap == 1 then
            pcall(vim.keymap.del, 'n', config.keymaps.to_true, { buf = ev.buf })
            vim.g.boolean_toggle_to_true_keymap = 0
          elseif under_cursor then
            vim.keymap.set(
              'n',
              config.keymaps.to_true,
              M.cursor_set_to_true,
              { buf = ev.buf, desc = 'Set Boolean on Cursor to `true`' }
            )
            vim.g.boolean_toggle_to_true_keymap = 1
          end
        end
      end,
    })
  end

  if not config.custom_spec then
    return
  end

  for _, spec in ipairs(config.custom_spec) do
    if not (spec.yes and spec.no) then
      vim.notify(
        ('Spec is missing either its `yes` and/or `no` values\nyes: `%s`\nno: `%s`'):format(
          spec.yes or '',
          spec.no or ''
        ),
        vim.log.levels.ERROR
      )
    end
  end
end

---@param bool? 'true'|'false'
---@return boolean is_boolean
---@return integer|nil|? start_col
---@return integer|nil|? end_col
---@return table<string, { [1]: string, ft: string[] }>|nil|? convert
function M.boolean_under_cursor(bool)
  M.util.validate({ bool = { bool, { 'string', 'nil' }, true } })
  if bool and not vim.list_contains({ 'true', 'false' }, bool) then
    error(('Invalid value `%s`'):format(bool))
  end

  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win())[2] + 1
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

  local ft = M.util.optget('filetype', 'buf', vim.api.nvim_get_current_buf()) --[[@as string]]
  local conv = M.get_spec_values('ft', bool and (bool == 'true' and 'true' or (bool == 'false' and 'false') or nil))
  if not conv[word] then
    return false
  end

  local conv_ft = conv[word].ft or { '*' }
  if vim.list_contains(conv_ft, ft) or #conv_ft == 0 or vim.list_contains(conv_ft, '*') then
    return true, start_col, col, conv
  end
  return false
end

---@return boolean success
function M.cursor_toggle_boolean()
  local bufnr = vim.api.nvim_get_current_buf()
  local ok, start_col, end_col, conv = M.boolean_under_cursor()
  local config = M.config.get()
  if
    not (
      ok
      and start_col
      and end_col
      and conv
      and vim.list_contains({ 'acwrite', '' }, vim.api.nvim_get_option_value('buftype', { buf = bufnr }))
    ) or vim.list_contains(config.ignore_ft, vim.api.nvim_get_option_value('filetype', { buf = bufnr }))
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

  if config.auto_write then
    success = pcall(vim.cmd.write, { mods = { noautocmd = true } })
  end
  return success
end

---@return boolean success
function M.cursor_set_to_false()
  local bufnr = vim.api.nvim_get_current_buf()
  local ok, start_col, end_col, conv = M.boolean_under_cursor('false')
  local config = M.config.get()
  if
    not (
      ok
      and start_col
      and end_col
      and conv
      and vim.list_contains({ 'acwrite', '' }, vim.api.nvim_get_option_value('buftype', { buf = bufnr }))
    ) or vim.list_contains(config.ignore_ft, vim.api.nvim_get_option_value('filetype', { buf = bufnr }))
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

  if config.auto_write then
    success = pcall(vim.cmd.write, { mods = { noautocmd = true } })
  end
  return success
end

---@return boolean success
function M.cursor_set_to_true()
  local bufnr = vim.api.nvim_get_current_buf()
  local ok, start_col, end_col, conv = M.boolean_under_cursor('true')
  local config = M.config.get()
  if
    not (
      ok
      and start_col
      and end_col
      and conv
      and vim.list_contains({ 'acwrite', '' }, vim.api.nvim_get_option_value('buftype', { buf = bufnr }))
    ) or vim.list_contains(config.ignore_ft, vim.api.nvim_get_option_value('filetype', { buf = bufnr }))
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
  if not vim.list_contains(vim.split('tTfFyYnN', ''), line:sub(pos[2] + 1, pos[2] + 1)) then
    pos[2] = pos[2] + (line:len() > (before .. conv[current_bool][1] .. after):len() and -1 or 1)
  end

  vim.api.nvim_set_current_line(before .. conv[line:sub(start_col, end_col)][1] .. after)
  local success = pcall(vim.cmd.undojoin)
  vim.api.nvim_win_set_cursor(win, pos)

  if config.auto_write then
    success = pcall(vim.cmd.write, { mods = { noautocmd = true } })
  end
  return success
end

return M
-- vim: set ts=2 sts=2 sw=2 et ai si sta:
