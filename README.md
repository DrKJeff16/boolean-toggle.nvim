# boolean-toggle.nvim

Toggle `true` and `false` values under your cursor.

---

## Table of Contents

- [Installation](#installation)
  - [`vim-plug`](#vim-plug)
  - [`lazy.nvim`](#lazynvim)
  - [`pckr.nvim`](#pckrnvim)
  - [`nvim-plug`](#nvim-plug)
  - [`paq-nvim`](#paq-nvim)
  - [`vim.pack`](#vimpack)
  - [LuaRocks](#luarocks)

---


## Installation

Requires Neovim >= `v0.11`

If you want to add instructions for your plugin manager of preference
please raise a [**_BLANK ISSUE_**](https://github.com/DrKJeff16/boolean-toggle.nvim/issues/new?template=BLANK_ISSUE).

Use any plugin manager of your choosing.

### `vim-plug`

```vim
if has('nvim-0.11')
  Plug 'DrKJeff16/boolean-toggle.nvim'

  lua << EOF
  require('boolean-toggle').setup()
  EOF
endif
```

### `lazy.nvim`

```lua
{
  'DrKJeff16/boolean-toggle.nvim',
  opts = {},
}
```

If you wish to lazy-load this plugin:

```lua
{
  'DrKJeff16/boolean-toggle.nvim',
  cmd = { 'Bool' }, -- Lazy-load by commands
  opts = {},
}
```

### `pckr.nvim`

```lua
require('pckr').add({
  {
    'DrKJeff16/boolean-toggle.nvim',
    config = function()
      require('boolean-toggle').setup()
    end,
  }
})
```

### `nvim-plug`

```lua
require('plug').add({
  {
    'DrKJeff16/boolean-toggle.nvim',
    config = function()
      require('boolean-toggle').setup()
    end,
  },
})
```

### `paq-nvim`

```lua
local paq = require('paq')
paq({ 'DrKJeff16/boolean-toggle.nvim' })
```

### `vim.pack`

```lua
vim.pack.add({
  { src = 'https://github.com/DrKJeff16/boolean-toggle.nvim', name = 'boolean-toggle.nvim' },
})
```

### LuaRocks

The package can be found [in the LuaRocks webpage](https://luarocks.org/modules/drkjeff16/boolean-toggle.nvim).

```bash
luarocks install boolean-toggle.nvim # Global install
luarocks install --local boolean-toggle.nvim # Local install
```

---

## Configuration

To enable the plugin you must call `setup()`:

```lua
require('boolean-toggle').setup()
```

### Defaults

You can find these in [`config.lua`](https://github.com/DrKJeff16/boolean-toggle.nvim/blob/main/lua/boolean-toggle/config.lua).

By default, `setup()` loads with the following options:

```lua
{
  auto_write = false, -- Whether to automatically save the file when a boolean is changed

  -- Normal mode keymaps
  --
  -- Each option can be either 'nil' or a keymap of your liking.
  -- MAKE SURE THEY DON'T OVERLAP!
  keymaps = {
    toggle = nil,    -- Toggles booleans under the cursor
    to_false = nil,  -- Sets boolean under cursor to `false`
    to_true = nil,   -- Sets boolean under cursor to `true`

    -- Or, if you wish to use them:
    --
    -- toggle = '<KEYMAP>',
    -- to_false = '<KEYMAP>',
    -- to_true = '<KEYMAP>',
  },
}
```

---

<!-- vim: set ts=2 sts=2 sw=2 et ai si sta: -->
