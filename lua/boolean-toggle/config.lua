---@class BooleanToggleOpts.Keymaps
---@field to_false? string
---@field to_true? string
---@field toggle? string

---@class BooleanToggleDefaults.Keymaps: BooleanToggleOpts.Keymaps
---@field to_false string|nil
---@field to_true string|nil
---@field toggle string|nil

---@class BooleanToggleOpts
---@field auto_write? boolean
---@field custom_spec? BooleanToggle.CustomSpec[]
---@field ignore_ft? string[]
---@field keymaps? BooleanToggleOpts.Keymaps

---@class BooleanToggle.CustomSpec
---@field ft? string[]
---@field no string
---@field yes string

---@class BooleanToggleDefaults: BooleanToggleOpts
---@field auto_write boolean
---@field custom_spec BooleanToggle.CustomSpec[]
---@field ignore_ft string[]
---@field keymaps BooleanToggleDefaults.Keymaps

local Util = require('boolean-toggle.util')

---@param config BooleanToggleDefaults
local function validate_config(config)
  Util.validate({
    config = { config, { 'table' } },
    ['config.auto_write'] = { config.auto_write, { 'boolean' } },
    ['config.custom_spec'] = { config.custom_spec, { 'table' } },
    ['config.ignore_ft'] = { config.ignore_ft, { 'table' } },
    ['config.keymaps'] = { config.keymaps, { 'table' } },
  })
end

---@class BooleanToggle.Config
local M = {}

---@return BooleanToggleDefaults defaults
function M.get_defaults()
  return { ---@type BooleanToggleDefaults
    auto_write = true,
    custom_spec = {},
    ignore_ft = {},
    keymaps = {},
  }
end

local config = M.get_defaults()

---@return BooleanToggleDefaults config
function M.get()
  return config
end

---@param opts BooleanToggleOpts
---@overload fun()
function M.setup(opts)
  Util.validate({ opts = { opts, { 'table', 'nil' }, true } })

  local defaults = M.get_defaults()
  config = vim.tbl_deep_extend('force', defaults, opts or {})

  for k in pairs(config) do
    if not defaults[k] then
      config[k] = nil
    end
  end

  validate_config(config)

  vim.g.boolean_nvim_setup = 1
end

return M
-- vim: set ts=2 sts=2 sw=2 et ai si sta:
