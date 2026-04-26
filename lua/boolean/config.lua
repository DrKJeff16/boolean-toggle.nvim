local Util = require('boolean.util')

---@class BooleanNvimOpts.Keymaps
---@field to_false? string
---@field to_true? string
---@field toggle? string

---@class BooleanNvimDefaults.Keymaps: BooleanNvimOpts.Keymaps
---@field to_false string
---@field to_true string
---@field toggle string

---@class BooleanNvimOpts
---@field keymaps? BooleanNvimOpts.Keymaps|nil

---@class BooleanNvimDefaults: BooleanNvimOpts
---@field keymaps BooleanNvimDefaults.Keymaps

---@class BooleanNvim.Config
---@field config BooleanNvimDefaults
local M = {}

---@return BooleanNvimDefaults defaults
function M.get_defaults()
  return { ---@type BooleanNvimDefaults
    keymaps = {
      toggle = '<M-b>',
      to_false = '<M-f>',
      to_true = '<M-t>',
    },
  }
end

---@param opts? BooleanNvimOpts
function M.setup(opts)
  Util.validate({ opts = { opts, { 'table', 'nil' }, true } })

  M.config = vim.tbl_deep_extend('keep', opts or {}, M.get_defaults())
  vim.g.boolean_nvim_setup = 1
end

return M
-- vim: set ts=2 sts=2 sw=2 et ai si sta:
