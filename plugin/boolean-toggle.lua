if vim.g.boolean_toggle_command_loaded == 1 then
  return
end

vim.g.boolean_toggle_command_loaded = 1

vim.api.nvim_create_user_command('Bool', function()
  require('boolean-toggle').cursor_toggle_boolean()
end, { desc = 'Invert Boolean Value on Cursor', nargs = 0 })
