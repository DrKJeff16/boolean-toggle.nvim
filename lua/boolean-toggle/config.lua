---@class BooleanToggleOpts.Keymaps
---@field to_false? string|nil
---@field to_true? string|nil
---@field toggle? string|nil

---@class BooleanToggleDefaults.Keymaps: BooleanToggleOpts.Keymaps
---@field to_false string|nil
---@field to_true string|nil
---@field toggle string|nil

---@class BooleanToggleOpts
---@field auto_write? boolean
---@field ignore_ft? string[]
---@field keymaps? BooleanToggleOpts.Keymaps|nil

---@class BooleanToggleDefaults: BooleanToggleOpts
---@field auto_write boolean
---@field ignore_ft string[]
---@field keymaps BooleanToggleDefaults.Keymaps

local Util = require('boolean-toggle.util')

---@class BooleanToggle.Config
---@field config BooleanToggleDefaults
local M = {}

---@return BooleanToggleDefaults defaults
function M.get_defaults()
  return { ---@type BooleanToggleDefaults
    auto_write = false,
    ignore_ft = {},
    keymaps = { toggle = nil, to_false = nil, to_true = nil },
  }
end

---@param opts? BooleanToggleOpts
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
