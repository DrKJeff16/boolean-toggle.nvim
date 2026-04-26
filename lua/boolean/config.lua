local Util = require('boolean.util')

---@class BooleanNvimOpts.Keymaps
---@field to_false? string|nil
---@field to_true? string|nil
---@field toggle? string|nil

---@class BooleanNvimDefaults.Keymaps: BooleanNvimOpts.Keymaps
---@field to_false string|nil
---@field to_true string|nil
---@field toggle string|nil

---@class BooleanNvimOpts
---@field auto_write? boolean
---@field keymaps? BooleanNvimOpts.Keymaps|nil

---@class BooleanNvimDefaults: BooleanNvimOpts
---@field auto_write boolean
---@field keymaps BooleanNvimDefaults.Keymaps

---@class BooleanNvim.Config
---@field config BooleanNvimDefaults
local M = {}

---@return BooleanNvimDefaults defaults
function M.get_defaults()
  return { ---@type BooleanNvimDefaults
    auto_write = false,
    keymaps = { toggle = nil, to_false = nil, to_true = nil },
  }
end

---@param opts? BooleanNvimOpts
function M.setup(opts)
  Util.validate({ opts = { opts, { 'table', 'nil' }, true } })

  local defaults = M.get_defaults()
  M.config = vim.tbl_deep_extend('keep', opts or {}, defaults)

  for k in pairs(M.config) do
    if not defaults[k] then
      M.config[k] = nil
    end
  end
  vim.g.boolean_nvim_setup = 1
end

return M
-- vim: set ts=2 sts=2 sw=2 et ai si sta:
